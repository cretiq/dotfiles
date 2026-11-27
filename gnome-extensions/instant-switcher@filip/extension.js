import {Extension, InjectionManager} from 'resource:///org/gnome/shell/extensions/extension.js';
import {SwitcherPopup} from 'resource:///org/gnome/shell/ui/switcherPopup.js';

export default class InstantSwitcher extends Extension {
    enable() {
        this._injections = new InjectionManager();
        this._injections.overrideMethod(SwitcherPopup.prototype, 'show', original => function (...args) {
            const shown = original.call(this, ...args);
            if (shown)
                this._showImmediately();
            return shown;
        });
    }

    disable() {
        this._injections.clear();
        this._injections = null;
    }
}
