import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import St from 'gi://St';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const NAME = 'org.gnome.Shell.Extensions.ClipboardBridge';
const PATH = '/org/gnome/Shell/Extensions/ClipboardBridge';
const IFACE = `<node><interface name="${NAME}">
  <method name="ListTypes">
    <arg type="b" direction="in" name="primary"/>
    <arg type="u" direction="out" name="status"/>
    <arg type="s" direction="out" name="path"/>
  </method>
  <method name="Read">
    <arg type="b" direction="in" name="primary"/>
    <arg type="s" direction="in" name="mimetype"/>
    <arg type="u" direction="out" name="status"/>
    <arg type="s" direction="out" name="path"/>
  </method>
</interface></node>`;

const OK = 0, NOTHING_COPIED = 1, TYPE_MISSING = 2, FAILED = 3;

export default class ClipboardBridge extends Extension {
    enable() {
        const dir = GLib.build_filenamev([GLib.get_user_runtime_dir(), 'clipboard-bridge']);
        GLib.mkdir_with_parents(dir, 0o700);
        this._service = new Service(dir);
        this._exported = Gio.DBusExportedObject.wrapJSObject(IFACE, this._service);
        this._exported.export(Gio.DBus.session, PATH);
        this._nameId = Gio.bus_own_name_on_connection(Gio.DBus.session, NAME,
            Gio.BusNameOwnerFlags.NONE, null, null);
    }

    disable() {
        Gio.bus_unown_name(this._nameId);
        this._exported.unexport();
        this._exported = null;
        this._service = null;
    }
}

class Service {
    constructor(dir) {
        this._dir = dir;
    }

    ListTypesAsync([primary], invocation) {
        const types = St.Clipboard.get_default().get_mimetypes(selection(primary));
        if (types.length === 0) {
            reply(invocation, NOTHING_COPIED);
            return;
        }
        const list = new TextEncoder().encode(types.map(type => `${type}\n`).join(''));
        this._hand(invocation, new GLib.Bytes(list));
    }

    ReadAsync([primary, mimetype], invocation) {
        const clipboard = St.Clipboard.get_default();
        const types = clipboard.get_mimetypes(selection(primary));
        if (types.length === 0) {
            reply(invocation, NOTHING_COPIED);
            return;
        }
        const type = mimetype ? types.find(t => t === mimetype) : defaultType(types);
        if (!type) {
            reply(invocation, TYPE_MISSING);
            return;
        }
        clipboard.get_content(selection(primary), type, (_, bytes) => {
            if (bytes === null)
                reply(invocation, FAILED);
            else
                this._hand(invocation, bytes);
        });
    }

    _hand(invocation, bytes) {
        const file = Gio.File.new_for_path(GLib.build_filenamev([this._dir, GLib.uuid_string_random()]));
        file.replace_contents_bytes_async(bytes, null, false, Gio.FileCreateFlags.PRIVATE, null,
            (_, result) => {
                try {
                    file.replace_contents_finish(result);
                } catch {
                    reply(invocation, FAILED);
                    return;
                }
                reply(invocation, OK, file.get_path());
            });
    }
}

function reply(invocation, status, path = '') {
    invocation.return_value(new GLib.Variant('(us)', [status, path]));
}

function selection(primary) {
    return primary ? St.ClipboardType.PRIMARY : St.ClipboardType.CLIPBOARD;
}

// wl-paste 2.2.1's pick when no --type is given and stdout has no file extension,
// so the wrapper's output matches the real wl-paste byte for byte.
function defaultType(types) {
    return ['text/plain;charset=utf-8', 'text/plain'].find(t => types.includes(t)) ??
        types.find(isText) ?? types[0];
}

function isText(type) {
    return type.startsWith('text/') || ['TEXT', 'STRING', 'UTF8_STRING'].includes(type) ||
        type.includes('json') || ['script', 'xml', 'yaml', 'csv', 'ini', 'pgp-keys'].some(s => type.endsWith(s)) ||
        type.includes('application/vnd.ms-publisher');
}
