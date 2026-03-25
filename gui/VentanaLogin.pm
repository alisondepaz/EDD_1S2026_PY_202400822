package VentanaLogin;

use strict;
use warnings;
use Gtk3 -init;
use Glib qw(TRUE FALSE);

sub nueva {
    my ($clase, $avl, $callback_admin, $callback_usuario) = @_;
    my $self = bless {
        avl        => $avl,
        cb_admin   => $callback_admin,
        cb_usuario => $callback_usuario,
    }, $clase;
    $self->_construir_ventana();
    return $self;
}

sub _aplicar_css {
    my $css = Gtk3::CssProvider->new();
    $css->load_from_data(<<'CSS');
window { background-color: #f0f4f8; }
.header-box { background-color: #1565c0; padding: 20px; }
.header-title { color: white; font-size: 22px; font-weight: bold; }
.header-sub { color: #bbdefb; font-size: 13px; }
.btn-primary { background-color: #1565c0; color: white; font-weight: bold; border-radius: 5px; padding: 8px 20px; }
.btn-secondary { background-color: #43a047; color: white; font-weight: bold; border-radius: 5px; padding: 8px 20px; }
.error-label { color: #c62828; font-size: 12px; }
CSS
    Gtk3::StyleContext::add_provider_for_screen(
        Gdk3::Screen::get_default(), $css,
        Gtk3::STYLE_PROVIDER_PRIORITY_APPLICATION
    );
}

sub _construir_ventana {
    my ($self) = @_;
    _aplicar_css();

    my $ventana = Gtk3::Window->new('toplevel');
    $ventana->set_title("EDD MedTrack F2 - Hospital General San Carlos");
    $ventana->set_default_size(720, 520);
    $ventana->set_position('center');
    $ventana->set_resizable(FALSE);
    $ventana->signal_connect(destroy => sub { Gtk3::main_quit(); });

    my $vbox_main = Gtk3::Box->new('vertical', 0);

    my $header = Gtk3::Box->new('vertical', 4);
    $header->get_style_context->add_class('header-box');
    my $lbl_titulo = Gtk3::Label->new("Hospital General San Carlos");
    $lbl_titulo->get_style_context->add_class('header-title');
    $lbl_titulo->set_halign('GTK_ALIGN_CENTER');
    my $lbl_sub = Gtk3::Label->new("Sistema EDD MedTrack - Fase 2  |  Gestion de Inventario Medico");
    $lbl_sub->get_style_context->add_class('header-sub');
    $lbl_sub->set_halign('GTK_ALIGN_CENTER');
    $header->pack_start($lbl_titulo, FALSE, FALSE, 0);
    $header->pack_start($lbl_sub,    FALSE, FALSE, 0);

    my $notebook = Gtk3::Notebook->new();
    $notebook->set_border_width(20);
    $notebook->append_page($self->_crear_tab_login(),    Gtk3::Label->new("Iniciar Sesion"));
    $notebook->append_page($self->_crear_tab_registro(), Gtk3::Label->new("Registro"));
    $notebook->append_page($self->_crear_tab_info(),     Gtk3::Label->new("Informacion del Sistema"));

    $vbox_main->pack_start($header,   FALSE, FALSE, 0);
    $vbox_main->pack_start($notebook, TRUE,  TRUE,  0);
    $ventana->add($vbox_main);
    $ventana->show_all();
    $self->{ventana} = $ventana;
}

sub _crear_tab_login {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 15);
    $vbox->set_border_width(30);
    $vbox->set_halign('GTK_ALIGN_CENTER');
    $vbox->set_valign('GTK_ALIGN_CENTER');

    my $grid = Gtk3::Grid->new();
    $grid->set_column_spacing(15);
    $grid->set_row_spacing(12);
    $grid->set_halign('GTK_ALIGN_CENTER');

    my $lbl_col = Gtk3::Label->new("Numero de Colegio:");
    $lbl_col->set_halign('GTK_ALIGN_END');
    my $entry_colegio = Gtk3::Entry->new();
    $entry_colegio->set_placeholder_text("Ej: COL-00051 o AdminHospital");
    $entry_colegio->set_width_chars(28);

    my $lbl_pass = Gtk3::Label->new("Contrasena:");
    $lbl_pass->set_halign('GTK_ALIGN_END');
    my $entry_pass = Gtk3::Entry->new();
    $entry_pass->set_visibility(FALSE);
    $entry_pass->set_placeholder_text("Ingrese su contrasena");
    $entry_pass->set_width_chars(28);

    $grid->attach($lbl_col,     0, 0, 1, 1);
    $grid->attach($entry_colegio,1, 0, 1, 1);
    $grid->attach($lbl_pass,    0, 1, 1, 1);
    $grid->attach($entry_pass,  1, 1, 1, 1);

    my $lbl_error = Gtk3::Label->new("");
    $lbl_error->get_style_context->add_class('error-label');

    my $btn = Gtk3::Button->new_with_label("Ingresar al Sistema");
    $btn->get_style_context->add_class('btn-primary');
    $btn->set_size_request(200, 40);
    $btn->set_halign('GTK_ALIGN_CENTER');

    $btn->signal_connect(clicked => sub {
        $self->_intentar_login($entry_colegio->get_text(), $entry_pass->get_text(), $lbl_error);
    });
    $entry_pass->signal_connect(activate => sub {
        $self->_intentar_login($entry_colegio->get_text(), $entry_pass->get_text(), $lbl_error);
    });

    $vbox->pack_start($grid,      FALSE, FALSE, 0);
    $vbox->pack_start($lbl_error, FALSE, FALSE, 0);
    $vbox->pack_start($btn,       FALSE, FALSE, 10);
    return $vbox;
}

sub _intentar_login {
    my ($self, $colegio, $pass, $lbl_error) = @_;
    $lbl_error->set_text("");
    if ($colegio eq 'AdminHospital' && $pass eq 'MedTrack2025') {
        $self->{ventana}->hide();
        $self->{cb_admin}->();
        return;
    }
    my $usuario = $self->{avl}->buscar($colegio);
    if (defined $usuario && $usuario->{contrasena} eq $pass) {
        $self->{ventana}->hide();
        $self->{cb_usuario}->($usuario);
    } else {
        $lbl_error->set_text("Credenciales incorrectas. Verifique su numero de colegio y contrasena.");
    }
}

sub _crear_tab_registro {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 12);
    $vbox->set_border_width(25);

    my $grid = Gtk3::Grid->new();
    $grid->set_column_spacing(15);
    $grid->set_row_spacing(10);

    my @campos = (["Numero de Colegio:", "COL-XXXXX"], ["Nombre Completo:", "Nombre y apellidos"],
                  ["Especialidad:",      "Opcional"],   ["Contrasena:",      "Minimo 6 caracteres"]);
    my @entries;
    for my $i (0 .. $#campos) {
        my $lbl   = Gtk3::Label->new($campos[$i][0]); $lbl->set_halign('GTK_ALIGN_END');
        my $entry = Gtk3::Entry->new();
        $entry->set_placeholder_text($campos[$i][1]);
        $entry->set_width_chars(26);
        $entry->set_visibility(FALSE) if $i == 3;
        $grid->attach($lbl,   0, $i, 1, 1);
        $grid->attach($entry, 1, $i, 1, 1);
        push @entries, $entry;
    }

    my $lbl_tipo = Gtk3::Label->new("Tipo de Usuario:"); $lbl_tipo->set_halign('GTK_ALIGN_END');
    my $combo_tipo = Gtk3::ComboBoxText->new();
    $combo_tipo->append_text($_) for ("TIPO-01 (Medico General)", "TIPO-02 (Medico Especialista)",
                                       "TIPO-03 (Enfermero/a)",    "TIPO-04 (Tecnico Laboratorio)");
    $combo_tipo->set_active(0);
    $grid->attach($lbl_tipo,   0, 4, 1, 1);
    $grid->attach($combo_tipo, 1, 4, 1, 1);

    my $lbl_dep = Gtk3::Label->new("Departamento:"); $lbl_dep->set_halign('GTK_ALIGN_END');
    my $combo_dep = Gtk3::ComboBoxText->new();
    $combo_dep->append_text($_) for ("DEP-MED", "DEP-CIR", "DEP-LAB", "DEP-FAR");
    $combo_dep->set_active(0);
    $grid->attach($lbl_dep,   0, 5, 1, 1);
    $grid->attach($combo_dep, 1, 5, 1, 1);

    my $lbl_msg = Gtk3::Label->new("");
    my $btn = Gtk3::Button->new_with_label("Registrar Usuario");
    $btn->get_style_context->add_class('btn-secondary');
    $btn->set_halign('GTK_ALIGN_CENTER');

    $btn->signal_connect(clicked => sub {
        my $col  = $entries[0]->get_text();
        my $nom  = $entries[1]->get_text();
        my $esp  = $entries[2]->get_text();
        my $pass = $entries[3]->get_text();
        my ($tipo) = ($combo_tipo->get_active_text() // '') =~ /^(TIPO-\d+)/;
        my $dep  = $combo_dep->get_active_text() // '';
        unless ($col && $nom && $pass) {
            $lbl_msg->set_markup('<span color="#c62828">Numero de colegio, nombre y contrasena son obligatorios.</span>');
            return;
        }
        if (defined $self->{avl}->buscar($col)) {
            $lbl_msg->set_markup('<span color="#c62828">El numero de colegio ya esta registrado.</span>');
            return;
        }
        $self->{avl}->insertar($col, $nom, $tipo, $dep, $esp, $pass);
        $lbl_msg->set_markup('<span color="#2e7d32">Usuario registrado exitosamente.</span>');
        $_->set_text("") for @entries;
    });

    $vbox->pack_start($grid,    FALSE, FALSE, 5);
    $vbox->pack_start($lbl_msg, FALSE, FALSE, 5);
    $vbox->pack_start($btn,     FALSE, FALSE, 5);
    return $vbox;
}

sub _crear_tab_info {
    my ($self) = @_;
    my $vbox = Gtk3::Box->new('vertical', 15);
    $vbox->set_border_width(30);
    $vbox->set_halign('GTK_ALIGN_CENTER');
    $vbox->set_valign('GTK_ALIGN_CENTER');

    my $frame = Gtk3::Frame->new();
    my $card  = Gtk3::Box->new('vertical', 10);
    $card->set_border_width(25);

    my $lbl_tit = Gtk3::Label->new();
    $lbl_tit->set_markup('<span font="15" weight="bold" color="#1565c0">Informacion del Desarrollador</span>');
    my $sep = Gtk3::Separator->new('horizontal');

    my @info = (
        ["Sistema:",     "EDD MedTrack F2 EST"],
        ["Curso:",       "Estructuras de Datos - USAC"],
        ["Facultad:",    "Ingenieria en Ciencias y Sistemas"],
        ["Lenguaje:",    "Perl + GTK3"],
        ["Reportes:",    "Graphviz"],
        ["Estructuras:", "BST, AVL, Arbol B Ord.4, Lista Doble, Lista Circ.Doble, Matriz Dispersa"],
    );

    my $grid = Gtk3::Grid->new();
    $grid->set_column_spacing(20);
    $grid->set_row_spacing(8);
    for my $i (0 .. $#info) {
        my $lk = Gtk3::Label->new(); $lk->set_markup("<b>$info[$i][0]</b>"); $lk->set_halign('GTK_ALIGN_END');
        my $lv = Gtk3::Label->new($info[$i][1]); $lv->set_halign('GTK_ALIGN_START');
        $grid->attach($lk, 0, $i, 1, 1);
        $grid->attach($lv, 1, $i, 1, 1);
    }

    $card->pack_start($lbl_tit, FALSE, FALSE, 0);
    $card->pack_start($sep,     FALSE, FALSE, 5);
    $card->pack_start($grid,    FALSE, FALSE, 0);
    $frame->add($card);
    $vbox->pack_start($frame, FALSE, FALSE, 0);
    return $vbox;
}

1;