package PanelAdmin;

use strict;
use warnings;
use Gtk3 -init;
use Glib qw(TRUE FALSE);
use lib '../lib';
use CargadorJSON;
use Reportes;

sub nuevo {
    my ($clase, %args) = @_;
    my $self = bless \%args, $clase;
    $self->_construir();
    return $self;
}

sub _construir {
    my ($self) = @_;
    my $ventana = Gtk3::Window->new('toplevel');
    $ventana->set_title("EDD MedTrack F2 - Panel de Administrador");
    $ventana->set_default_size(1100, 700);
    $ventana->set_position('center');
    $ventana->signal_connect(destroy => sub { Gtk3::main_quit(); });
    $self->{ventana} = $ventana;

    my $hbox = Gtk3::Box->new('horizontal', 0);
    $hbox->pack_start($self->_crear_sidebar(),              FALSE, FALSE, 0);
    $hbox->pack_start(Gtk3::Separator->new('vertical'),     FALSE, FALSE, 0);

    my $stack = Gtk3::Stack->new();
    $stack->set_transition_type('GTK_STACK_TRANSITION_TYPE_SLIDE_LEFT_RIGHT');
    $stack->set_transition_duration(200);
    $self->{stack} = $stack;

    $stack->add_named($self->_vista_dashboard(),            "dashboard");
    $stack->add_named($self->_vista_inventario_equipo(),    "equipos");
    $stack->add_named($self->_vista_inventario_suministro(),"suministros");
    $stack->add_named($self->_vista_medicamentos(),         "medicamentos");
    $stack->add_named($self->_vista_personal(),             "personal");
    $stack->add_named($self->_vista_carga_inventario(),     "carga_inv");
    $stack->add_named($self->_vista_carga_usuarios(),       "carga_usr");
    $stack->add_named($self->_vista_matriz(),               "matriz");
    $stack->add_named($self->_vista_reportes(),             "reportes");
    $stack->set_visible_child_name("dashboard");

    $hbox->pack_start($stack, TRUE, TRUE, 0);
    $ventana->add($hbox);
    $ventana->show_all();
}

sub _crear_sidebar {
    my ($self) = @_;
    my $sidebar = Gtk3::Box->new('vertical', 5);
    $sidebar->set_size_request(220, -1);
    $sidebar->set_border_width(10);

    my $lbl_logo = Gtk3::Label->new();
    $lbl_logo->set_markup('<span font="12" weight="bold" color="#1565c0">MedTrack F2</span>');
    my $lbl_admin = Gtk3::Label->new();
    $lbl_admin->set_markup('<span font="10" color="#555">Panel de Administrador</span>');
    $sidebar->pack_start($lbl_logo,  FALSE, FALSE, 0);
    $sidebar->pack_start($lbl_admin, FALSE, FALSE, 0);
    $sidebar->pack_start(Gtk3::Separator->new('horizontal'), FALSE, FALSE, 5);

    my @botones = (
        ["Inicio / Resumen",           "dashboard"],
        ["Equipos (BST)",              "equipos"],
        ["Suministros (Arbol B)",      "suministros"],
        ["Medicamentos",               "medicamentos"],
        ["Personal Medico (AVL)",      "personal"],
        ["Carga Inventario JSON",      "carga_inv"],
        ["Carga Usuarios JSON",        "carga_usr"],
        ["Matriz Proveedor/Fab.",      "matriz"],
        ["Reportes Graphviz",          "reportes"],
    );

    for my $item (@botones) {
        my $btn = Gtk3::Button->new_with_label($item->[0]);
        my $vista = $item->[1];
        $btn->set_relief('GTK_RELIEF_NONE');
        $btn->set_halign('GTK_ALIGN_FILL');
        $btn->signal_connect(clicked => sub { $self->{stack}->set_visible_child_name($vista); });
        $sidebar->pack_start($btn, FALSE, FALSE, 2);
    }

    $sidebar->pack_start(Gtk3::Separator->new('horizontal'), FALSE, FALSE, 5);
    my $btn_logout = Gtk3::Button->new_with_label("Cerrar Sesion");
    $btn_logout->set_relief('GTK_RELIEF_NONE');
    $btn_logout->signal_connect(clicked => sub {
        $self->{ventana}->hide();
        $self->{cb_logout}->() if $self->{cb_logout};
    });
    $sidebar->pack_end($btn_logout, FALSE, FALSE, 5);
    return $sidebar;
}

sub _vista_dashboard {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 15);
    $vbox->set_border_width(25);
    my $lbl = Gtk3::Label->new();
    $lbl->set_markup('<span font="18" weight="bold" color="#1565c0">Panel de Control - Administrador</span>');
    my $lbl2 = Gtk3::Label->new("Seleccione una seccion en el menu lateral para comenzar.");
    $vbox->pack_start($lbl,  FALSE, FALSE, 10);
    $vbox->pack_start($lbl2, FALSE, FALSE, 5);
    return $vbox;
}

sub _vista_inventario_equipo {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 10);
    $vbox->set_border_width(20);

    my $lbl_tit = Gtk3::Label->new();
    $lbl_tit->set_markup('<span font="15" weight="bold">Inventario de Equipos Medicos (Arbol BST)</span>');
    $vbox->pack_start($lbl_tit, FALSE, FALSE, 5);

    my $frame_form = Gtk3::Frame->new("Registrar / Buscar / Eliminar Equipo");
    my $grid = Gtk3::Grid->new();
    $grid->set_column_spacing(10); $grid->set_row_spacing(8); $grid->set_border_width(12);

    my @campos = (["Codigo:",0],["Nombre:",1],["Fabricante:",2],
                  ["Precio:",3],["Cantidad:",4],["Fecha Ingreso:",5],["Nivel Minimo:",6]);
    my %ent;
    for my $c (@campos) {
        my $lbl = Gtk3::Label->new($c->[0]); $lbl->set_halign('GTK_ALIGN_END');
        my $e   = Gtk3::Entry->new(); $e->set_width_chars(20);
        $grid->attach($lbl, 0, $c->[1], 1, 1);
        $grid->attach($e,   1, $c->[1], 1, 1);
        (my $k = $c->[0]) =~ s/[^a-zA-Z]//g;
        $ent{$k} = $e;
    }

    my $hbox_btn = Gtk3::Box->new('horizontal', 8); $hbox_btn->set_border_width(8);
    for my $op ("Insertar","Buscar","Eliminar") {
        my $btn = Gtk3::Button->new_with_label($op);
        $btn->signal_connect(clicked => sub { $self->_operacion_bst($op, \%ent); });
        $hbox_btn->pack_start($btn, FALSE, FALSE, 0);
    }

    my $hbox_rec = Gtk3::Box->new('horizontal', 8); $hbox_rec->set_border_width(8);
    my $combo_rec = Gtk3::ComboBoxText->new();
    $combo_rec->append_text($_) for ("In-Orden","Pre-Orden","Post-Orden");
    $combo_rec->set_active(0);
    my $btn_rec = Gtk3::Button->new_with_label("Ver Recorrido");
    $btn_rec->signal_connect(clicked => sub { $self->_mostrar_recorrido_bst($combo_rec->get_active_text()); });
    $hbox_rec->pack_start(Gtk3::Label->new("Recorrido:"), FALSE, FALSE, 0);
    $hbox_rec->pack_start($combo_rec, FALSE, FALSE, 0);
    $hbox_rec->pack_start($btn_rec,   FALSE, FALSE, 0);

    my $store = Gtk3::ListStore->new(qw(Glib::String Glib::String Glib::String Glib::Double Glib::Int Glib::String Glib::Int));
    my $tv    = Gtk3::TreeView->new($store);
    my @cols  = ("Codigo","Nombre","Fabricante","Precio","Cantidad","F.Ingreso","Niv.Min");
    for my $i (0 .. $#cols) {
        my $r = Gtk3::CellRendererText->new();
        my $c = Gtk3::TreeViewColumn->new_with_attributes($cols[$i], $r, text => $i);
        $c->set_resizable(TRUE); $tv->append_column($c);
    }
    my $scroll = Gtk3::ScrolledWindow->new(); $scroll->add($tv); $scroll->set_vexpand(TRUE);
    $self->{store_bst} = $store;

    $frame_form->add($grid);
    $vbox->pack_start($frame_form, FALSE, FALSE, 0);
    $vbox->pack_start($hbox_btn,   FALSE, FALSE, 0);
    $vbox->pack_start($hbox_rec,   FALSE, FALSE, 0);
    $vbox->pack_start($scroll,     TRUE,  TRUE,  0);
    $self->_refrescar_tabla_bst();
    return $vbox;
}

sub _operacion_bst {
    my ($self, $op, $ent) = @_;
    my $codigo = (($ent->{Cdigo} // $ent->{Codigo} // Gtk3::Entry->new())->get_text()) + 0;
    if ($op eq 'Insertar') {
        my $nom   = $ent->{Nombre}->get_text();
        my $fab   = $ent->{Fabricante}->get_text();
        my $prec  = $ent->{Precio}->get_text() + 0;
        my $cant  = $ent->{Cantidad}->get_text() + 0;
        my $fecha = $ent->{FechaIngreso}->get_text();
        my $nivel = $ent->{NivelMnimo} ? $ent->{NivelMnimo}->get_text()+0 : $ent->{NivelMinimo}->get_text()+0;
        return unless $codigo && $nom;
        $self->{bst}->insertar($codigo, $nom, $fab, $prec, $cant, $fecha, $nivel);
        $self->_refrescar_tabla_bst();
        $self->_msg("Equipo $codigo insertado/actualizado en el BST.");
    } elsif ($op eq 'Buscar') {
        return unless $codigo;
        my $n = $self->{bst}->buscar($codigo);
        $self->_msg($n ? "Equipo: $n->{nombre} | Cant: $n->{cantidad} | Fab: $n->{fabricante}" : "Codigo $codigo no encontrado.");
    } elsif ($op eq 'Eliminar') {
        return unless $codigo;
        $self->{bst}->eliminar($codigo);
        $self->_refrescar_tabla_bst();
        $self->_msg("Equipo $codigo eliminado del BST.");
    }
}

sub _refrescar_tabla_bst {
    my ($self) = @_;
    return unless defined $self->{store_bst};
    $self->{store_bst}->clear();
    for my $n ($self->{bst}->inorden()) {
        $self->{store_bst}->set($self->{store_bst}->append(),
            0,"$n->{codigo}", 1,$n->{nombre}, 2,$n->{fabricante},
            3,$n->{precio}+0, 4,$n->{cantidad}+0, 5,$n->{fecha_ingreso}, 6,$n->{nivel_minimo}+0);
    }
}

sub _mostrar_recorrido_bst {
    my ($self, $tipo) = @_;
    my @nodos = $tipo eq 'In-Orden'   ? $self->{bst}->inorden()
              : $tipo eq 'Pre-Orden'  ? $self->{bst}->preorden()
              :                         $self->{bst}->postorden();
    my $txt = join("\n", map { "[$_->{codigo}] $_->{nombre} (x$_->{cantidad})" } @nodos);
    $self->_dialogo_texto("Recorrido BST: $tipo", $txt || "(arbol vacio)");
}

sub _vista_inventario_suministro {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 10);
    $vbox->set_border_width(20);
    my $lbl = Gtk3::Label->new();
    $lbl->set_markup('<span font="15" weight="bold">Inventario de Suministros (Arbol B Orden 4)</span>');
    $vbox->pack_start($lbl, FALSE, FALSE, 5);

    my $frame = Gtk3::Frame->new("Registrar / Buscar / Eliminar Suministro");
    my $grid  = Gtk3::Grid->new();
    $grid->set_column_spacing(10); $grid->set_row_spacing(8); $grid->set_border_width(12);

    my @campos = (["Codigo:",0],["Nombre:",1],["Fabricante:",2],
                  ["Precio:",3],["Cantidad:",4],["Fecha Venc.:",5],["Nivel Minimo:",6]);
    my %ent;
    for my $c (@campos) {
        my $lbl = Gtk3::Label->new($c->[0]); $lbl->set_halign('GTK_ALIGN_END');
        my $e   = Gtk3::Entry->new(); $e->set_width_chars(20);
        $grid->attach($lbl, 0, $c->[1], 1, 1);
        $grid->attach($e,   1, $c->[1], 1, 1);
        (my $k = $c->[0]) =~ s/[^a-zA-Z]//g;
        $ent{$k} = $e;
    }

    my $hbox_btn = Gtk3::Box->new('horizontal', 8); $hbox_btn->set_border_width(8);
    for my $op ("Insertar","Buscar","Eliminar") {
        my $btn = Gtk3::Button->new_with_label($op);
        $btn->signal_connect(clicked => sub { $self->_operacion_arbolb($op, \%ent); });
        $hbox_btn->pack_start($btn, FALSE, FALSE, 0);
    }

    my $store = Gtk3::ListStore->new(qw(Glib::String Glib::String Glib::String Glib::Double Glib::Int Glib::String Glib::Int));
    my $tv    = Gtk3::TreeView->new($store);
    for my $i (0..6) {
        my $r = Gtk3::CellRendererText->new();
        my $c = Gtk3::TreeViewColumn->new_with_attributes(
            ("Codigo","Nombre","Fabricante","Precio","Cantidad","F.Venc","Niv.Min")[$i], $r, text => $i);
        $c->set_resizable(TRUE); $tv->append_column($c);
    }
    my $scroll = Gtk3::ScrolledWindow->new(); $scroll->add($tv); $scroll->set_vexpand(TRUE);
    $self->{store_arbolb} = $store;

    $frame->add($grid);
    $vbox->pack_start($frame,    FALSE, FALSE, 0);
    $vbox->pack_start($hbox_btn, FALSE, FALSE, 0);
    $vbox->pack_start($scroll,   TRUE,  TRUE,  0);
    $self->_refrescar_tabla_arbolb();
    return $vbox;
}

sub _operacion_arbolb {
    my ($self, $op, $ent) = @_;
    my $codigo = (($ent->{Cdigo} // $ent->{Codigo} // Gtk3::Entry->new())->get_text()) + 0;
    if ($op eq 'Insertar') {
        my $nom   = $ent->{Nombre}->get_text();
        my $fab   = $ent->{Fabricante}->get_text();
        my $prec  = $ent->{Precio}->get_text() + 0;
        my $cant  = $ent->{Cantidad}->get_text() + 0;
        my $fecha = $ent->{FechaVenc}->get_text();
        my $nivel = $ent->{NivelMnimo} ? $ent->{NivelMnimo}->get_text()+0 : $ent->{NivelMinimo}->get_text()+0;
        return unless $codigo && $nom;
        $self->{arbol_b}->insertar($codigo, $nom, $fab, $prec, $cant, $fecha, $nivel);
        $self->_refrescar_tabla_arbolb();
    } elsif ($op eq 'Buscar') {
        return unless $codigo;
        my $d = $self->{arbol_b}->buscar($codigo);
        $self->_msg($d ? "Suministro: $d->{nombre} | Cant: $d->{cantidad} | Vence: $d->{fecha_vencimiento}" : "Codigo $codigo no encontrado.");
    } elsif ($op eq 'Eliminar') {
        return unless $codigo;
        $self->{arbol_b}->eliminar($codigo);
        $self->_refrescar_tabla_arbolb();
    }
}

sub _refrescar_tabla_arbolb {
    my ($self) = @_;
    return unless defined $self->{store_arbolb};
    $self->{store_arbolb}->clear();
    for my $d ($self->{arbol_b}->inorden()) {
        $self->{store_arbolb}->set($self->{store_arbolb}->append(),
            0,"$d->{codigo}", 1,$d->{nombre}, 2,$d->{fabricante},
            3,$d->{precio}+0, 4,$d->{cantidad}+0, 5,$d->{fecha_vencimiento}, 6,$d->{nivel_minimo}+0);
    }
}

sub _vista_medicamentos {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 10);
    $vbox->set_border_width(20);
    my $lbl = Gtk3::Label->new();
    $lbl->set_markup('<span font="15" weight="bold">Medicamentos (Lista Doblemente Enlazada)</span>');
    $vbox->pack_start($lbl, FALSE, FALSE, 5);

    my $store = Gtk3::ListStore->new(qw(Glib::String Glib::String Glib::String Glib::String Glib::Double Glib::Int Glib::String Glib::Int));
    my $tv    = Gtk3::TreeView->new($store);
    my @cols  = ("Codigo","Nombre","Principio Activo","Fabricante","Precio","Cantidad","F.Venc","Niv.Min");
    for my $i (0 .. $#cols) {
        my $r = Gtk3::CellRendererText->new();
        my $c = Gtk3::TreeViewColumn->new_with_attributes($cols[$i], $r, text => $i);
        $c->set_resizable(TRUE); $tv->append_column($c);
    }
    my $scroll = Gtk3::ScrolledWindow->new(); $scroll->add($tv); $scroll->set_vexpand(TRUE);
    $self->{store_med} = $store;
    $self->_refrescar_tabla_med();

    my $btn = Gtk3::Button->new_with_label("Refrescar");
    $btn->signal_connect(clicked => sub { $self->_refrescar_tabla_med(); });
    $vbox->pack_start($scroll, TRUE,  TRUE,  0);
    $vbox->pack_start($btn,    FALSE, FALSE, 5);
    return $vbox;
}

sub _refrescar_tabla_med {
    my ($self) = @_;
    return unless defined $self->{store_med};
    $self->{store_med}->clear();
    for my $n ($self->{lista_med}->todos()) {
        $self->{store_med}->set($self->{store_med}->append(),
            0,"$n->{codigo}", 1,$n->{nombre}, 2,$n->{principio_activo},
            3,$n->{fabricante}, 4,$n->{precio}+0, 5,$n->{cantidad}+0,
            6,$n->{fecha_vencimiento}, 7,$n->{nivel_minimo}+0);
    }
}

sub _vista_personal {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 10);
    $vbox->set_border_width(20);
    my $lbl = Gtk3::Label->new();
    $lbl->set_markup('<span font="15" weight="bold">Personal Medico (Arbol AVL)</span>');
    $vbox->pack_start($lbl, FALSE, FALSE, 5);

    my $hbox = Gtk3::Box->new('horizontal', 10);
    my $entry_bus = Gtk3::Entry->new();
    $entry_bus->set_placeholder_text("Numero de colegio para buscar/eliminar");
    $entry_bus->set_width_chars(25);
    my $btn_bus = Gtk3::Button->new_with_label("Buscar");
    my $btn_eli = Gtk3::Button->new_with_label("Eliminar");
    my $combo_rec = Gtk3::ComboBoxText->new();
    $combo_rec->append_text($_) for ("In-Orden","Pre-Orden","Post-Orden");
    $combo_rec->set_active(0);
    my $btn_rec = Gtk3::Button->new_with_label("Ver Recorrido");
    $hbox->pack_start($entry_bus, FALSE, FALSE, 0);
    $hbox->pack_start($btn_bus,   FALSE, FALSE, 0);
    $hbox->pack_start($btn_eli,   FALSE, FALSE, 0);
    $hbox->pack_start($combo_rec, FALSE, FALSE, 5);
    $hbox->pack_start($btn_rec,   FALSE, FALSE, 0);

    my $hbox_fil = Gtk3::Box->new('horizontal', 10);
    my $combo_dep = Gtk3::ComboBoxText->new();
    $combo_dep->append_text("Todos");
    $combo_dep->append_text($_) for ("DEP-MED","DEP-CIR","DEP-LAB","DEP-FAR");
    $combo_dep->set_active(0);
    my $btn_fil = Gtk3::Button->new_with_label("Filtrar");
    $hbox_fil->pack_start(Gtk3::Label->new("Filtrar por departamento:"), FALSE, FALSE, 0);
    $hbox_fil->pack_start($combo_dep, FALSE, FALSE, 0);
    $hbox_fil->pack_start($btn_fil,   FALSE, FALSE, 0);

    my $store = Gtk3::ListStore->new(qw(Glib::String Glib::String Glib::String Glib::String Glib::String));
    my $tv    = Gtk3::TreeView->new($store);
    for my $i (0..4) {
        my $r = Gtk3::CellRendererText->new();
        my $c = Gtk3::TreeViewColumn->new_with_attributes(
            ("N.Colegio","Nombre","Tipo","Departamento","Especialidad")[$i], $r, text => $i);
        $c->set_resizable(TRUE); $tv->append_column($c);
    }
    my $scroll = Gtk3::ScrolledWindow->new(); $scroll->add($tv); $scroll->set_vexpand(TRUE);
    $self->{store_avl} = $store;
    $self->_refrescar_tabla_avl();

    $btn_bus->signal_connect(clicked => sub {
        my $col = $entry_bus->get_text();
        my $u   = $self->{avl}->buscar($col);
        $self->_msg($u ? "Usuario: $u->{nombre} | $u->{tipo} | $u->{departamento}" : "No encontrado: $col");
    });
    $btn_eli->signal_connect(clicked => sub {
        my $col = $entry_bus->get_text();
        $self->{avl}->eliminar($col); $self->_refrescar_tabla_avl();
        $self->_msg("Usuario $col eliminado del AVL.");
    });
    $btn_rec->signal_connect(clicked => sub {
        my $tipo = $combo_rec->get_active_text();
        my @ns   = $tipo eq 'In-Orden'   ? $self->{avl}->inorden()
                 : $tipo eq 'Pre-Orden'  ? $self->{avl}->preorden()
                 :                         $self->{avl}->postorden();
        my $txt  = join("\n", map { "$_->{numero_colegio} - $_->{nombre} ($_->{tipo})" } @ns);
        $self->_dialogo_texto("Recorrido AVL: $tipo", $txt || "(vacio)");
    });
    $btn_fil->signal_connect(clicked => sub {
        my $dep = $combo_dep->get_active_text();
        $self->_refrescar_tabla_avl($dep eq 'Todos' ? undef : $dep);
    });

    $vbox->pack_start($hbox,     FALSE, FALSE, 5);
    $vbox->pack_start($hbox_fil, FALSE, FALSE, 5);
    $vbox->pack_start($scroll,   TRUE,  TRUE,  0);
    return $vbox;
}

sub _refrescar_tabla_avl {
    my ($self, $filtro) = @_;
    return unless defined $self->{store_avl};
    $self->{store_avl}->clear();
    for my $u ($self->{avl}->inorden()) {
        next if defined $filtro && $u->{departamento} ne $filtro;
        $self->{store_avl}->set($self->{store_avl}->append(),
            0,$u->{numero_colegio}, 1,$u->{nombre},
            2,$u->{tipo}, 3,$u->{departamento}, 4,$u->{especialidad});
    }
}

sub _vista_carga_inventario {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 15); $vbox->set_border_width(25);
    my $lbl  = Gtk3::Label->new();
    $lbl->set_markup('<span font="15" weight="bold">Carga Masiva de Inventario desde JSON</span>');
    $vbox->pack_start($lbl, FALSE, FALSE, 0);

    my $btn      = Gtk3::Button->new_with_label("Seleccionar Archivo JSON...");
    $btn->set_size_request(280, 40); $btn->set_halign('GTK_ALIGN_CENTER');
    my $lbl_ruta = Gtk3::Label->new("(ningun archivo seleccionado)");
    $lbl_ruta->set_selectable(TRUE);

    my $textbuf = Gtk3::TextBuffer->new();
    my $tv      = Gtk3::TextView->new_with_buffer($textbuf);
    $tv->set_editable(FALSE); $tv->set_wrap_mode('GTK_WRAP_WORD');
    my $scroll = Gtk3::ScrolledWindow->new(); $scroll->add($tv); $scroll->set_size_request(-1, 200);

    $btn->signal_connect(clicked => sub {
        my $dialog = Gtk3::FileChooserDialog->new(
            "Seleccionar JSON", $self->{ventana}, 'GTK_FILE_CHOOSER_ACTION_OPEN',
            "Cancelar", 'GTK_RESPONSE_CANCEL', "Abrir", 'GTK_RESPONSE_ACCEPT');
        my $f = Gtk3::FileFilter->new(); $f->set_name("JSON"); $f->add_pattern("*.json"); $dialog->add_filter($f);
        if ($dialog->run() eq 'GTK_RESPONSE_ACCEPT') {
            my $ruta = $dialog->get_filename(); $lbl_ruta->set_text($ruta); $dialog->destroy();
            my $res = CargadorJSON::cargar_inventario(
                $ruta, $self->{avl}, $self->{bst}, $self->{arbol_b},
                $self->{lista_med}, $self->{lista_prov}, $self->{matriz});
            my $log = "=== Resultados ===\nExitosos: $res->{exitosos}\nErrores: $res->{errores}\n\n";
            $log .= join("\n", @{$res->{mensajes}});
            $log .= "\n--- Advertencias ---\n" . join("\n", @{$res->{advertencias}});
            $textbuf->set_text($log);
            $self->_refrescar_tabla_bst(); $self->_refrescar_tabla_arbolb(); $self->_refrescar_tabla_med();
        } else { $dialog->destroy(); }
    });

    $vbox->pack_start($btn,      FALSE, FALSE, 5);
    $vbox->pack_start($lbl_ruta, FALSE, FALSE, 0);
    $vbox->pack_start($scroll,   FALSE, FALSE, 5);
    return $vbox;
}

sub _vista_carga_usuarios {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 15); $vbox->set_border_width(25);
    my $lbl  = Gtk3::Label->new();
    $lbl->set_markup('<span font="15" weight="bold">Carga Masiva de Usuarios desde JSON</span>');
    $vbox->pack_start($lbl, FALSE, FALSE, 0);

    my $btn      = Gtk3::Button->new_with_label("Seleccionar Archivo JSON...");
    $btn->set_size_request(280, 40); $btn->set_halign('GTK_ALIGN_CENTER');
    my $lbl_ruta = Gtk3::Label->new("(ningun archivo seleccionado)");
    my $textbuf  = Gtk3::TextBuffer->new();
    my $tv       = Gtk3::TextView->new_with_buffer($textbuf);
    $tv->set_editable(FALSE);
    my $scroll = Gtk3::ScrolledWindow->new(); $scroll->add($tv); $scroll->set_size_request(-1, 200);

    $btn->signal_connect(clicked => sub {
        my $dialog = Gtk3::FileChooserDialog->new(
            "Seleccionar JSON de Usuarios", $self->{ventana}, 'GTK_FILE_CHOOSER_ACTION_OPEN',
            "Cancelar", 'GTK_RESPONSE_CANCEL', "Abrir", 'GTK_RESPONSE_ACCEPT');
        if ($dialog->run() eq 'GTK_RESPONSE_ACCEPT') {
            my $ruta = $dialog->get_filename(); $lbl_ruta->set_text($ruta); $dialog->destroy();
            my $res  = CargadorJSON::cargar_usuarios($ruta, $self->{avl});
            my $log  = "=== Carga de Usuarios ===\nExitosos: $res->{exitosos}\nErrores: $res->{errores}\n\n";
            $log    .= join("\n", @{$res->{mensajes}}) . "\n" . join("\n", @{$res->{advertencias}});
            $textbuf->set_text($log);
            $self->_refrescar_tabla_avl();
        } else { $dialog->destroy(); }
    });

    $vbox->pack_start($btn,      FALSE, FALSE, 5);
    $vbox->pack_start($lbl_ruta, FALSE, FALSE, 0);
    $vbox->pack_start($scroll,   FALSE, FALSE, 5);
    return $vbox;
}

sub _vista_matriz {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 10); $vbox->set_border_width(20);
    my $lbl  = Gtk3::Label->new();
    $lbl->set_markup('<span font="15" weight="bold">Matriz Dispersa - Proveedor vs Fabricante</span>');
    $vbox->pack_start($lbl, FALSE, FALSE, 5);

    my @proveedores = $self->{matriz}->proveedores();
    my @fabricantes = $self->{matriz}->fabricantes();

    unless (@proveedores && @fabricantes) {
        $vbox->pack_start(Gtk3::Label->new("Matriz vacia. Cargue inventario primero."), FALSE, FALSE, 20);
        return $vbox;
    }

    my @tipos = ("Glib::String", map { "Glib::Int" } @fabricantes);
    my $store = Gtk3::ListStore->new(@tipos);
    my $tv    = Gtk3::TreeView->new($store);

    my $r0 = Gtk3::CellRendererText->new();
    my $c0 = Gtk3::TreeViewColumn->new_with_attributes("Proveedor", $r0, text => 0);
    $c0->set_resizable(TRUE); $tv->append_column($c0);

    for my $i (0 .. $#fabricantes) {
        my $r = Gtk3::CellRendererText->new();
        my $c = Gtk3::TreeViewColumn->new_with_attributes($fabricantes[$i], $r, text => $i+1);
        $c->set_resizable(TRUE); $tv->append_column($c);
    }

    for my $nit (@proveedores) {
        my $iter = $store->append();
        $store->set($iter, 0, $self->{matriz}->nombre_proveedor($nit));
        for my $j (0 .. $#fabricantes) {
            $store->set($iter, $j+1, $self->{matriz}->consultar($nit, $fabricantes[$j])+0);
        }
    }

    my $scroll = Gtk3::ScrolledWindow->new(); $scroll->add($tv); $scroll->set_vexpand(TRUE);
    $vbox->pack_start($scroll, TRUE, TRUE, 0);
    return $vbox;
}

sub _vista_reportes {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 15); $vbox->set_border_width(20);
    my $lbl  = Gtk3::Label->new();
    $lbl->set_markup('<span font="15" weight="bold">Reportes Graficos con Graphviz</span>');
    $vbox->pack_start($lbl, FALSE, FALSE, 5);

    my $grid = Gtk3::Grid->new();
    $grid->set_column_spacing(15); $grid->set_row_spacing(15); $grid->set_border_width(15);
    $grid->set_halign('GTK_ALIGN_CENTER');

    my @reportes = (
        ["Arbol AVL (Personal Medico)",         sub { Reportes::reporte_avl($self->{avl})              }],
        ["Arbol BST (Equipos)",                 sub { Reportes::reporte_bst($self->{bst})              }],
        ["Arbol B Ord.4 (Suministros)",         sub { Reportes::reporte_arbol_b($self->{arbol_b})      }],
        ["Matriz Dispersa",                     sub { Reportes::reporte_matriz($self->{matriz})        }],
        ["Medicamentos (Lista Doble)",           sub { Reportes::reporte_medicamentos($self->{lista_med}) }],
        ["Proveedores (Lista Circ. Doble)",     sub { Reportes::reporte_proveedores($self->{lista_prov}) }],
    );

    for my $i (0 .. $#reportes) {
        my $btn = Gtk3::Button->new_with_label($reportes[$i][0]);
        $btn->set_size_request(200, 55);
        my $gen = $reportes[$i][1];
        $btn->signal_connect(clicked => sub {
            my $ruta = $gen->();
            if (defined $ruta && -f $ruta) { $self->_mostrar_imagen($ruta); }
            else { $self->_msg("Error al generar el reporte. Verifique que Graphviz este instalado."); }
        });
        $grid->attach($btn, $i % 3, int($i / 3), 1, 1);
    }

    my $scroll_img = Gtk3::ScrolledWindow->new();
    my $img        = Gtk3::Image->new();
    $scroll_img->add($img); $scroll_img->set_vexpand(TRUE);
    $self->{img_reporte} = $img;

    $vbox->pack_start($grid,       FALSE, FALSE, 0);
    $vbox->pack_start($scroll_img, TRUE,  TRUE,  0);
    return $vbox;
}

sub _mostrar_imagen {
    my ($self, $ruta) = @_;
    return unless -f $ruta;
    my $pixbuf = Gtk3::Gdk::Pixbuf->new_from_file_at_scale($ruta, 900, 500, TRUE);
    $self->{img_reporte}->set_from_pixbuf($pixbuf);
}

sub _msg {
    my ($self, $mensaje) = @_;
    my $d = Gtk3::MessageDialog->new(
        $self->{ventana}, 'GTK_DIALOG_MODAL',
        'GTK_MESSAGE_INFO', 'GTK_BUTTONS_OK', $mensaje);
    $d->run(); $d->destroy();
}

sub _dialogo_texto {
    my ($self, $titulo, $texto) = @_;
    my $d = Gtk3::Dialog->new($titulo, $self->{ventana}, 'GTK_DIALOG_MODAL');
    $d->set_default_size(500, 400);
    my $buf = Gtk3::TextBuffer->new(); $buf->set_text($texto);
    my $tv  = Gtk3::TextView->new_with_buffer($buf);
    $tv->set_editable(FALSE); $tv->set_wrap_mode('GTK_WRAP_WORD');
    my $scroll = Gtk3::ScrolledWindow->new(); $scroll->add($tv);
    $d->get_content_area()->pack_start($scroll, TRUE, TRUE, 5);
    $d->add_button("Cerrar", 'GTK_RESPONSE_OK');
    $d->show_all(); $d->run(); $d->destroy();
}

1;