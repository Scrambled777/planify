/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alainmh23@gmail.com>
*/

public class Views.TaskList : Gtk.EventBox {
    public E.Source source { get; set; }
    private ECal.ClientView view;
    
    private Gtk.Label name_label;
    private Widgets.Entry name_entry;
    private Gtk.Stack name_stack;
    private Gtk.Revealer action_revealer;
    private Gtk.ListBox listbox;
    private Gtk.ListBox completed_listbox;
    private Gtk.Revealer completed_revealer;
    private Gtk.ToggleButton settings_button;
    private Gtk.Stack main_stack;
    private Widgets.ProjectProgress project_progress;
    private Gtk.Popover popover = null;
    private Gtk.Switch show_completed_switch;
    private Gtk.ModelButton show_completed_button;

    public Gee.HashMap <string, Widgets.TaskRow> items_uncompleted_added;
    public Gee.HashMap <string, Widgets.TaskRow> items_completed_added;
    private static Services.Tasks.Store task_store;
    private bool entry_menu_opened = false;
    private Gee.Collection<ECal.ClientView> views;
    private E.SourceTaskList task_list;

    construct {
        views = new Gee.ArrayList<ECal.ClientView> ((Gee.EqualDataFunc<ECal.ClientView>?) direct_equal);
        task_store = Services.Tasks.Store.get_default ();
        items_uncompleted_added = new Gee.HashMap <string, Widgets.TaskRow> ();
        items_completed_added = new Gee.HashMap <string, Widgets.TaskRow> ();

        var color_popover = new Widgets.ColorPopover ();

        project_progress = new Widgets.ProjectProgress (16);
        project_progress.valign = Gtk.Align.CENTER;
        project_progress.halign = Gtk.Align.CENTER;

        var progress_button = new Gtk.MenuButton ();
        progress_button.valign = Gtk.Align.START;
        progress_button.get_style_context ().add_class ("no-padding");
        progress_button.get_style_context ().add_class ("flat");
        progress_button.add (project_progress);
        progress_button.popover = color_popover;
        progress_button.margin_end = 6;
        progress_button.margin_top = 2;
        
        name_label = new Gtk.Label (null);
        name_label.halign = Gtk.Align.START;
        name_label.get_style_context ().add_class ("title-label");
        name_label.get_style_context ().add_class ("font-bold");

        var name_eventbox = new Gtk.EventBox ();
        name_eventbox.valign = Gtk.Align.START;
        name_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        name_eventbox.hexpand = true;
        name_eventbox.add (name_label);

        name_entry = new Widgets.Entry ();
        name_entry.get_style_context ().add_class ("font-bold");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("title-label");
        name_entry.get_style_context ().add_class ("project-name-entry");
        name_entry.hexpand = true;

        name_stack = new Gtk.Stack ();
        name_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        name_stack.add_named (name_eventbox, "name_label");
        name_stack.add_named (name_entry, "name_entry");

        var submit_button = new Gtk.Button.with_label (_("Save"));
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("planner-button");

        var action_grid = new Gtk.Grid ();
        action_grid.halign = Gtk.Align.START;
        action_grid.margin_top = 6;
        action_grid.column_homogeneous = true;
        action_grid.column_spacing = 6;
        action_grid.margin_start = 42;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);

        action_revealer = new Gtk.Revealer ();
        action_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        action_revealer.add (action_grid);

        var settings_image = new Gtk.Image ();
        settings_image.gicon = new ThemedIcon ("view-more-symbolic");
        settings_image.pixel_size = 14;

        settings_button = new Gtk.ToggleButton ();
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.can_focus = false;
        settings_button.tooltip_text = _("Project Menu");
        settings_button.image = settings_image;
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_end = 36;
        top_box.margin_start = 42;
        top_box.margin_top = 6;

        top_box.pack_start (progress_button, false, false, 0);
        top_box.pack_start (name_stack, false, true, 0);
        top_box.pack_end (settings_button, false, false, 0);

        listbox = new Gtk.ListBox ();
        listbox.margin_start = 32;
        listbox.margin_top = 12;
        listbox.margin_end = 32;
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        completed_listbox = new Gtk.ListBox ();
        completed_listbox.margin_start = 32;
        completed_listbox.margin_end = 32;
        completed_listbox.valign = Gtk.Align.START;
        completed_listbox.get_style_context ().add_class ("listbox");
        completed_listbox.activate_on_single_click = true;
        completed_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        completed_listbox.hexpand = true;

        completed_revealer = new Gtk.Revealer ();
        completed_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        completed_revealer.add (completed_listbox);
        completed_revealer.reveal_child = true;

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.expand = true;
        box.pack_start (listbox, false, false, 0);
        box.pack_start (completed_revealer, false, false, 0);

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null);
        listbox_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        listbox_scrolled.add (box);

        var magic_button = new Widgets.MagicButton ();

        var placeholder_view = new Widgets.Placeholder (
            _("What will you accomplish?"),
            _("Tap + to add a task to this project."),
            "planner-project-symbolic"
        );
        placeholder_view.reveal_child = true;
        placeholder_view.show_all ();

        main_stack = new Gtk.Stack ();
        main_stack.expand = true;
        main_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        main_stack.add_named (placeholder_view, "placeholder");
        main_stack.add_named (listbox_scrolled, "tasklist");

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (action_revealer, false, false, 0);
        main_box.pack_start (main_stack, false, true, 0);

        var overlay = new Gtk.Overlay ();
        overlay.expand = true;
        overlay.add_overlay (magic_button);
        overlay.add (main_box);

        add (overlay);
        
        notify["source"].connect (() => {
            task_list = ((E.SourceTaskList?) source.get_extension (E.SOURCE_EXTENSION_TASK_LIST));
            project_progress.progress_fill_color = task_list.dup_color ();
            remove_views ();

            foreach (unowned Gtk.Widget child in listbox.get_children ()) {
                child.destroy ();
            }

            foreach (unowned Gtk.Widget child in completed_listbox.get_children ()) {
                child.destroy ();
            }

            add_view (source, "(contains? 'any' '')");
            update_request ();

            show_all ();
        });

        Planner.event_bus.edit_tasklist.connect ((uid) => {
            if (source.uid == uid) {
                action_revealer.reveal_child = true;
                name_stack.visible_child_name = "name_entry";
                name_entry.grab_focus ();
            }
        });

        settings_button.toggled.connect (() => {
            Planner.event_bus.unselect_all ();

            if (settings_button.active) {
                if (popover == null) {
                    create_popover ();
                }

                // show_completed_switch.active = project.show_completed == 1;
                // board_switch.active = project.is_kanban == 1;

                popover.show_all ();
            }
        });
        
        listbox.row_activated.connect ((r) => {
            var row = ((Widgets.TaskRow) r);
            row.reveal_child = true;
        });

        completed_listbox.row_activated.connect ((r) => {
            var row = ((Widgets.TaskRow) r);
            row.reveal_child = true;
        });

        color_popover.color_changed.connect ((color) => {
            task_list.color = Planner.utils.get_color (color);
            source.write.begin (null);
        });

        cancel_button.clicked.connect (() => {
            action_revealer.reveal_child = false;
            name_stack.visible_child_name = "name_label";
            name_entry.text = source.display_name;
        });
        
        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                action_revealer.reveal_child = false;
                name_stack.visible_child_name = "name_label";
                name_entry.text = source.display_name;
            }

            return false;
        });

        name_entry.focus_out_event.connect (() => {
            if (entry_menu_opened == false) {
                save ();
            }
        });

        name_entry.populate_popup.connect ((menu) => {
            entry_menu_opened = true;
            menu.hide.connect (() => {
                entry_menu_opened = false;
            });
        });

        name_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                action_revealer.reveal_child = true;
                name_stack.visible_child_name = "name_entry";

                name_entry.grab_focus_without_selecting ();
                if (name_entry.cursor_position < name_entry.text_length) {
                    name_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) name_entry.text_length, false);
                }
            }

            return false;
        });

        name_entry.changed.connect (() => {
            if (name_entry.text.strip () != "" && source.display_name != name_entry.text) {
                submit_button.sensitive = true;
            } else {
                submit_button.sensitive = false;
            }
        });

        submit_button.clicked.connect (() => {
            save ();
        });

        name_entry.activate.connect (() => {
            save ();
        });

        magic_button.clicked.connect (() => {
            add_new_task (Planner.settings.get_enum ("new-tasks-position"));
        });

        task_store.task_list_modified.connect ((s) => {
            if (source.uid == s.uid) {
                update_request ();
            }
        });
    }

    private void create_popover () {
        popover = new Gtk.Popover (settings_button);
        popover.get_style_context ().add_class ("popover-background");
        popover.position = Gtk.PositionType.BOTTOM;

        var delete_menu = new Widgets.ModelButton (_("Delete"), "user-trash-symbolic");
        delete_menu.get_style_context ().add_class ("menu-danger");

        // Show Complete
        var show_completed_image = new Gtk.Image ();
        show_completed_image.gicon = new ThemedIcon ("emblem-default-symbolic");
        show_completed_image.valign = Gtk.Align.START;
        show_completed_image.pixel_size = 16;

        var show_completed_label = new Gtk.Label (_("Show Completed"));
        show_completed_label.hexpand = true;
        show_completed_label.valign = Gtk.Align.START;
        show_completed_label.xalign = 0;
        show_completed_label.margin_start = 9;

        show_completed_switch = new Gtk.Switch ();
        show_completed_switch.margin_start = 12;
        show_completed_switch.get_style_context ().add_class ("planner-switch");

        var show_completed_grid = new Gtk.Grid ();
        show_completed_grid.add (show_completed_image);
        show_completed_grid.add (show_completed_label);
        show_completed_grid.add (show_completed_switch);

        show_completed_button = new Gtk.ModelButton ();
        show_completed_button.get_style_context ().add_class ("popover-model-button");
        show_completed_button.get_child ().destroy ();
        show_completed_button.add (show_completed_grid);

        var popover_grid = new Gtk.Grid ();
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.margin_top = 3;
        popover_grid.margin_bottom = 3;
        popover_grid.add (show_completed_button);
        popover_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3,
            margin_bottom = 3
        });
        popover_grid.add (delete_menu);
        popover.add (popover_grid);

        delete_menu.clicked.connect (() => {
            popover.popdown ();
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Delete project"),
                _("Are you sure you want to delete <b>%s</b>?".printf (Planner.utils.get_dialog_text (source.display_name))),
                "user-trash-full",
            Gtk.ButtonsType.CANCEL);

            var remove_button = new Gtk.Button.with_label (_("Delete"));
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();

            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                if (source.removable) {
                    source.remove.begin (null);
                } else {
                    Gdk.beep ();
                }
            }

            message_dialog.destroy ();
        });
    }

    private void remove_views () {
        items_completed_added.clear ();
        items_uncompleted_added.clear ();

        lock (views) {
            foreach (ECal.ClientView view in views) {
                task_store.destroy_task_list_view (view);
            }
            views.clear ();
        }

        check_tasklist_placeholder ();
    }

    public void add_view (E.Source task_list, string query) {
        try {
            var view = task_store.create_task_list_view (
                task_list,
                query,
                on_tasks_added,
                on_tasks_modified,
                on_tasks_removed);

            lock (views) {
                views.add (view);
            }

        } catch (Error e) {
            critical (e.message);
        }
    }

    public void add_new_task (int index=-1) {
        main_stack.visible_child_name = "tasklist";

        var new_task = new Widgets.TaskRow.for_source (source);
        listbox.add (new_task);
        listbox.show_all ();
    }

    private void save () {
        task_store.update_task_list_display_name.begin (source, name_entry.text, (obj, res) => {
            GLib.Idle.add (() => {
                try {
                    task_store.update_task_list_display_name.end (res);
                    action_revealer.reveal_child = false;
                    name_stack.visible_child_name = "name_label";
                    source.display_name = name_entry.text;
                } catch (Error e) {
                    name_entry.text = source.display_name;
                    name_label.label = source.display_name;
                    action_revealer.reveal_child = false;
                    name_stack.visible_child_name = "name_label";
                    print ("Error: %s\n".printf (e.message));
                }

                return GLib.Source.REMOVE;
            });
        });
    }

    private void on_tasks_added (Gee.Collection<ECal.Component> tasks) {
        foreach (ECal.Component task in tasks) {
            unowned ICal.Component ical_task = task.get_icalcomponent ();
            if (ical_task.get_status () == ICal.PropertyStatus.COMPLETED) {
                if (!items_completed_added.has_key (task.get_icalcomponent ().get_uid ())) {
                    var row = new Widgets.TaskRow.for_component (task, source);
                    completed_listbox.add (row);
                    items_completed_added.set (task.get_icalcomponent ().get_uid (), row);
                }
            } else {
                if (!items_uncompleted_added.has_key (task.get_icalcomponent ().get_uid ())) {
                    var row = new Widgets.TaskRow.for_component (task, source);
                    listbox.add (row);

                    items_uncompleted_added.set (task.get_icalcomponent ().get_uid (), row);
                }
            }
        }

        listbox.show_all ();
        completed_listbox.show_all ();
        check_tasklist_placeholder ();
    }

    private void on_tasks_modified (Gee.Collection<ECal.Component> tasks) {
        foreach (ECal.Component task in tasks) {
            unowned ICal.Component ical_task = task.get_icalcomponent ();
            if (ical_task.get_status () == ICal.PropertyStatus.COMPLETED) {
                if (items_uncompleted_added.has_key (task.get_icalcomponent ().get_uid ())) {
                    items_uncompleted_added.get (task.get_icalcomponent ().get_uid ()).hide_destroy ();
                    items_uncompleted_added.unset (task.get_icalcomponent ().get_uid ());   
                }

                if (!items_completed_added.has_key (task.get_icalcomponent ().get_uid ())) {
                    var row = new Widgets.TaskRow.for_component (task, source);
                    completed_listbox.insert (row, 0);

                    items_completed_added.set (task.get_icalcomponent ().get_uid (), row);
                } else {
                    items_completed_added.get (task.get_icalcomponent ().get_uid ()).task = task;
                }
            } else {
                if (items_completed_added.has_key (task.get_icalcomponent ().get_uid ())) {
                    items_completed_added.get (task.get_icalcomponent ().get_uid ()).hide_destroy ();
                    items_completed_added.unset (task.get_icalcomponent ().get_uid ());
                }

                if (!items_uncompleted_added.has_key (task.get_icalcomponent ().get_uid ())) {
                    var row = new Widgets.TaskRow.for_component (task, source);
                    listbox.add (row);

                    items_uncompleted_added.set (task.get_icalcomponent ().get_uid (), row);
                } else {
                    items_uncompleted_added.get (task.get_icalcomponent ().get_uid ()).task = task;
                }
            }
        }

        listbox.show_all ();
        completed_listbox.show_all ();
        check_tasklist_placeholder ();
    }

    private void on_tasks_removed (SList<weak ECal.ComponentId?> cids) {
        unowned Widgets.TaskRow? task_row = null;
        var row_index = 0;
        do {
            task_row = (Widgets.TaskRow) listbox.get_row_at_index (row_index);

            if (task_row != null) {
                foreach (unowned ECal.ComponentId cid in cids) {
                    if (cid == null) {
                        continue;
                    } else if (cid.get_uid () == task_row.task.get_icalcomponent ().get_uid ()) {
                        listbox.remove (task_row);
                        break;
                    }
                }
            }
            row_index++;
        } while (task_row != null);

        check_tasklist_placeholder ();
    }

    public void update_request () {
        name_label.label = source.dup_display_name ();
        name_entry.text = source.dup_display_name ();
        project_progress.progress_fill_color = task_list.dup_color ();

        listbox.@foreach ((row) => {
            if (row is Widgets.TaskRow) {
                (row as Widgets.TaskRow).update_request ();
            }
        });
    }

    private void check_tasklist_placeholder () {
        if (items_uncompleted_added.size > 0) {
            main_stack.visible_child_name = "tasklist";
        } else {
            main_stack.visible_child_name = "placeholder";
        }
    }
}