package PanelUsuario;

use strict;
use warnings;
use Gtk3 -init;
use Glib qw(TRUE FALSE);

my %PERMISOS = (
    'DEP-MED' => { medicamentos => 1, suministros => 1, equipos => 0 },
    'DEP-CIR' => { medicamentos => 0, suministros => 1, equipos => 1 },
    'DEP-LAB' => { medicamentos => 0, suministros => 0, equipos => 1 },
    'DEP-FAR' => { medicamentos => 1, suministros => 0, equipos => 0 },
    'DEP-ADM' => { medicamentos => 1, suministros => 1, equipos => 1 },
);

sub nuevo {
    my ($clase, %args) = @_;
    my $self = bless \%args, $clase;
    $self->_construir();
    return $self;
}

sub _construir {
    my ($self) = @_;
    my $dep = $self->{usuario}{departamento} // 'DEP-MED';
    my $ventana = Gtk3::Window->new('toplevel');
    $ventana->set_title("EDD MedTrack F2 - $self->{usuario}{nombre} ($dep)");
    $ventana->set_default_size(950, 620);
    $ventana->set_position('center');
    $ventana->signal_connect(destroy => sub { Gtk3::main_quit(); });
    $self->{ventana} = $ventana;

    my $hbox = Gtk3::Box->new('horizontal', 0);
    $hbox->pack_start($self->_crear_sidebar($dep),      FALSE, FALSE, 0);
    $hbox->pack_start(Gtk3::Separator->new('vertical'), FALSE, FALSE, 0);

    my $stack = Gtk3::Stack->new();
    $stack->set_transition_type('GTK_STACK_TRANSITION_TYPE_SLIDE_LEFT_RIGHT');
    $stack->set_transition_duration(200);
    $self->{stack} = $stack;

    my $p = $PERMISOS{$dep} // {};
    $stack->add_named($self->_vista_inicio($dep),      "inicio");
    $stack->add_named($self->_vista_medicamentos(),    "medicamentos") if $p->{medicamentos};
    $stack->add_named($self->_vista_equipos(),         "equipos")      if $p->{equipos};
    $stack->add_named($self->_vista_suministros(),     "suministros")  if $p->{suministros};
    $stack->add_named($self->_vista_perfil(),          "perfil");
    $stack->set_visible_child_name("inicio");

    $hbox->pack_start($stack, TRUE, TRUE, 0);
    $ventana->add($hbox);
    $ventana->show_all();
}

sub _crear_sidebar {
    my ($self, $dep) = @_;
    my $sidebar = Gtk3::Box->new('vertical', 5);
    $sidebar->set_size_request(200, -1);
    $sidebar->set_border_width(10);

    my $lbl_logo = Gtk3::Label->new();
    $lbl_logo->set_markup('<span font="12" weight="bold" color="#1565c0">MedTrack F2</span>');
    my $lbl_user = Gtk3::Label->new($self->{usuario}{nombre} // '');
    $lbl_user->set_line_wrap(TRUE);
    $sidebar->pack_start($lbl_logo, FALSE, FALSE, 0);
    $sidebar->pack_start($lbl_user, FALSE, FALSE, 0);
    $sidebar->pack_start(Gtk3::Separator->new('horizontal'), FALSE, FALSE, 5);

    my $p = $PERMISOS{$dep} // {};
    my @botones = (["Inicio","inicio"],["Mi Perfil","perfil"]);
    push @botones, ["Medicamentos","medicamentos"] if $p->{medicamentos};
    push @botones, ["Equipos",     "equipos"]      if $p->{equipos};
    push @botones, ["Suministros", "suministros"]  if $p->{suministros};

    for my $item (@botones) {
        my $btn = Gtk3::Button->new_with_label($item->[0]);
        my $v   = $item->[1];
        $btn->set_relief('GTK_RELIEF_NONE');
        $btn->signal_connect(clicked => sub { $self->{stack}->set_visible_child_name($v); });
        $sidebar->pack_start($btn, FALSE, FALSE, 2);
    }

    $sidebar->pack_start(Gtk3::Separator->new('horizontal'), FALSE, FALSE, 5);
    my $btn_out = Gtk3::Button->new_with_label("Cerrar Sesion");
    $btn_out->set_relief('GTK_RELIEF_NONE');
    $btn_out->signal_connect(clicked => sub {
        $self->{ventana}->hide();
        $self->{cb_logout}->() if $self->{cb_logout};
    });
    $sidebar->pack_end($btn_out, FALSE, FALSE, 5);
    return $sidebar;
}

sub _vista_inicio {
    my ($self, $dep) = @_;
    my $vbox = Gtk3::Box->new('vertical', 15); $vbox->set_border_width(25);
    my $u    = $self->{usuario};
    my $lbl  = Gtk3::Label->new();
    $lbl->set_markup("<span font='16' weight='bold'>Bienvenido/a, $u->{nombre}</span>");
    $vbox->pack_start($lbl, FALSE, FALSE, 10);

    my $frame = Gtk3::Frame->new("Informacion de Sesion");
    my $grid  = Gtk3::Grid->new(); $grid->set_column_spacing(20); $grid->set_row_spacing(10); $grid->set_border_width(15);
    my @info  = (["Numero de Colegio:", $u->{numero_colegio}],["Tipo:", $u->{tipo}],
                 ["Departamento:", $dep],["Especialidad:", $u->{especialidad} // 'N/A']);
    for my $i (0 .. $#info) {
        my $lk = Gtk3::Label->new(); $lk->set_markup("<b>$info[$i][0]</b>"); $lk->set_halign('GTK_ALIGN_END');
        my $lv = Gtk3::Label->new($info[$i][1]); $lv->set_halign('GTK_ALIGN_START');
        $grid->attach($lk, 0, $i, 1, 1); $grid->attach($lv, 1, $i, 1, 1);
    }
    $frame->add($grid);
    $vbox->pack_start($frame, FALSE, FALSE, 0);
    return $vbox;
}

sub _vista_medicamentos {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 10); $vbox->set_border_width(20);
    my $lbl  = Gtk3::Label->new();
    $lbl->set_markup('<span font="14" weight="bold">Consulta de Medicamentos</span>');
    $vbox->pack_start($lbl, FALSE, FALSE, 5);

    my $hbox  = Gtk3::Box->new('horizontal', 10);
    my $entry = Gtk3::Entry->new(); $entry->set_placeholder_text("Codigo"); $entry->set_width_chars(15);
    my $btn   = Gtk3::Button->new_with_label("Buscar");
    $hbox->pack_start(Gtk3::Label->new("Codigo:"), FALSE, FALSE, 0);
    $hbox->pack_start($entry, FALSE, FALSE, 0);
    $hbox->pack_start($btn,   FALSE, FALSE, 0);

    my $lbl_res = Gtk3::Label->new(""); $lbl_res->set_line_wrap(TRUE);

    $btn->signal_connect(clicked => sub {
        my $cod = $entry->get_text();
        return unless $cod =~ /^\d+$/;
        my $n = $self->{lista_med}->buscar(int($cod));
        if ($n) {
            my $alerta = $n->{cantidad} < $n->{nivel_minimo} ? "\nSTOCK BAJO DEL NIVEL MINIMO" : "";
            $lbl_res->set_markup("<b>$n->{nombre}</b>\nPrincipio: $n->{principio_activo}\n" .
                "Cantidad: $n->{cantidad} | Vence: $n->{fecha_vencimiento}" .
                "<span color='red'>$alerta</span>");
        } else {
            $lbl_res->set_text("Medicamento codigo $cod no encontrado.");
        }
    });

    my $store = Gtk3::ListStore->new(qw(Glib::String Glib::String Glib::String Glib::Int Glib::String Glib::String));
    my $tv    = Gtk3::TreeView->new($store);
    for my $i (0..5) {
        my $r = Gtk3::CellRendererText->new();
        my $c = Gtk3::TreeViewColumn->new_with_attributes(
            ("Codigo","Nombre","Principio Activo","Cantidad","F.Venc","Estado")[$i], $r, text => $i);
        $c->set_resizable(TRUE); $tv->append_column($c);
    }
    for my $n ($self->{lista_med}->todos()) {
        my $estado = $n->{cantidad} < $n->{nivel_minimo} ? "BAJO STOCK" : "OK";
        $store->set($store->append(),
            0,"$n->{codigo}", 1,$n->{nombre}, 2,$n->{principio_activo},
            3,$n->{cantidad}+0, 4,$n->{fecha_vencimiento}, 5,$estado);
    }
    my $scroll = Gtk3::ScrolledWindow->new(); $scroll->add($tv); $scroll->set_vexpand(TRUE);

    $vbox->pack_start($hbox,    FALSE, FALSE, 5);
    $vbox->pack_start($lbl_res, FALSE, FALSE, 5);
    $vbox->pack_start($scroll,  TRUE,  TRUE,  0);
    return $vbox;
}

sub _vista_equipos {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 10); $vbox->set_border_width(20);
    my $lbl  = Gtk3::Label->new();
    $lbl->set_markup('<span font="14" weight="bold">Consulta de Equipos Medicos</span>');
    $vbox->pack_start($lbl, FALSE, FALSE, 5);

    my $hbox  = Gtk3::Box->new('horizontal', 10);
    my $entry = Gtk3::Entry->new(); $entry->set_placeholder_text("Codigo"); $entry->set_width_chars(15);
    my $btn   = Gtk3::Button->new_with_label("Buscar en BST");
    $hbox->pack_start(Gtk3::Label->new("Codigo:"), FALSE, FALSE, 0);
    $hbox->pack_start($entry, FALSE, FALSE, 0);
    $hbox->pack_start($btn,   FALSE, FALSE, 0);

    my $lbl_res = Gtk3::Label->new(""); $lbl_res->set_line_wrap(TRUE);
    $btn->signal_connect(clicked => sub {
        my $cod = $entry->get_text();
        return unless $cod =~ /^\d+$/;
        my $n = $self->{bst}->buscar(int($cod));
        $lbl_res->set_markup($n
            ? "<b>$n->{nombre}</b>\nFabricante: $n->{fabricante} | Precio: Q$n->{precio}\nCantidad: $n->{cantidad} | Ingreso: $n->{fecha_ingreso}"
            : "Equipo codigo $cod no encontrado.");
    });
    $vbox->pack_start($hbox,    FALSE, FALSE, 5);
    $vbox->pack_start($lbl_res, FALSE, FALSE, 5);
    return $vbox;
}

sub _vista_suministros {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 10); $vbox->set_border_width(20);
    my $lbl  = Gtk3::Label->new();
    $lbl->set_markup('<span font="14" weight="bold">Consulta de Suministros</span>');
    $vbox->pack_start($lbl, FALSE, FALSE, 5);

    my $hbox  = Gtk3::Box->new('horizontal', 10);
    my $entry = Gtk3::Entry->new(); $entry->set_placeholder_text("Codigo"); $entry->set_width_chars(15);
    my $btn   = Gtk3::Button->new_with_label("Buscar en Arbol B");
    $hbox->pack_start(Gtk3::Label->new("Codigo:"), FALSE, FALSE, 0);
    $hbox->pack_start($entry, FALSE, FALSE, 0);
    $hbox->pack_start($btn,   FALSE, FALSE, 0);

    my $lbl_res = Gtk3::Label->new(""); $lbl_res->set_line_wrap(TRUE);
    $btn->signal_connect(clicked => sub {
        my $cod = $entry->get_text();
        return unless $cod =~ /^\d+$/;
        my $d = $self->{arbol_b}->buscar(int($cod));
        if ($d) {
            my $alerta = $d->{cantidad} < $d->{nivel_minimo} ? "\nSTOCK BAJO DEL NIVEL MINIMO" : "";
            $lbl_res->set_markup("<b>$d->{nombre}</b>\nFabricante: $d->{fabricante} | Precio: Q$d->{precio}\n" .
                "Cantidad: $d->{cantidad} | Vence: $d->{fecha_vencimiento}<span color='red'>$alerta</span>");
        } else {
            $lbl_res->set_text("Suministro codigo $cod no encontrado.");
        }
    });
    $vbox->pack_start($hbox,    FALSE, FALSE, 5);
    $vbox->pack_start($lbl_res, FALSE, FALSE, 5);
    return $vbox;
}

sub _vista_perfil {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 15); $vbox->set_border_width(25);
    my $lbl  = Gtk3::Label->new();
    $lbl->set_markup('<span font="14" weight="bold">Mi Perfil</span>');
    $vbox->pack_start($lbl, FALSE, FALSE, 5);

    my $u     = $self->{usuario};
    my $frame = Gtk3::Frame->new("Informacion Registrada");
    my $grid  = Gtk3::Grid->new(); $grid->set_column_spacing(15); $grid->set_row_spacing(10); $grid->set_border_width(15);

    my $lbl_col = Gtk3::Label->new("N. Colegio:"); $lbl_col->set_halign('GTK_ALIGN_END');
    my $val_col = Gtk3::Label->new($u->{numero_colegio} // ''); $val_col->set_halign('GTK_ALIGN_START');

    my $lbl_nom = Gtk3::Label->new("Nombre:");      $lbl_nom->set_halign('GTK_ALIGN_END');
    my $ent_nom = Gtk3::Entry->new(); $ent_nom->set_text($u->{nombre} // ''); $ent_nom->set_width_chars(28);

    my $lbl_dep = Gtk3::Label->new("Departamento:"); $lbl_dep->set_halign('GTK_ALIGN_END');
    my $val_dep = Gtk3::Label->new($u->{departamento} // ''); $val_dep->set_halign('GTK_ALIGN_START');

    my $lbl_pass= Gtk3::Label->new("Nueva Contrasena:"); $lbl_pass->set_halign('GTK_ALIGN_END');
    my $ent_pass= Gtk3::Entry->new(); $ent_pass->set_visibility(FALSE); $ent_pass->set_width_chars(28);
    $ent_pass->set_placeholder_text("(dejar vacio para no cambiar)");

    $grid->attach($lbl_col,  0, 0, 1, 1); $grid->attach($val_col,  1, 0, 1, 1);
    $grid->attach($lbl_nom,  0, 1, 1, 1); $grid->attach($ent_nom,  1, 1, 1, 1);
    $grid->attach($lbl_dep,  0, 2, 1, 1); $grid->attach($val_dep,  1, 2, 1, 1);
    $grid->attach($lbl_pass, 0, 3, 1, 1); $grid->attach($ent_pass, 1, 3, 1, 1);
    $frame->add($grid);

    my $lbl_msg = Gtk3::Label->new("");
    my $btn = Gtk3::Button->new_with_label("Guardar Cambios"); $btn->set_halign('GTK_ALIGN_CENTER');
    $btn->signal_connect(clicked => sub {
        my $nom  = $ent_nom->get_text();
        my $pass = $ent_pass->get_text();
        if ($nom)  { $u->{nombre}     = $nom;  }
        if ($pass) { $u->{contrasena} = $pass; }
        my $nodo = $self->{avl}->buscar($u->{numero_colegio});
        if (defined $nodo) {
            $nodo->{nombre}     = $u->{nombre}     if $nom;
            $nodo->{contrasena} = $u->{contrasena} if $pass;
        }
        $lbl_msg->set_markup('<span color="#2e7d32">Perfil actualizado correctamente.</span>');
    });

    $vbox->pack_start($frame,   FALSE, FALSE, 0);
    $vbox->pack_start($lbl_msg, FALSE, FALSE, 5);
    $vbox->pack_start($btn,     FALSE, FALSE, 0);
    return $vbox;
}

1;