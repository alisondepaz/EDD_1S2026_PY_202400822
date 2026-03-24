use strict;
use warnings;
use lib 'lib';
use lib 'gui';
use Gtk3 -init;

use ArbolAVL;
use ArbolBST;
use ArbolB;
use ListaDoble;
use ListaCircularDoble;
use MatrizDispersa;
use VentanaLogin;
use PanelAdmin;
use PanelUsuario;

my $avl        = ArbolAVL->new();
my $bst        = ArbolBST->new();
my $arbol_b    = ArbolB->new();
my $lista_med  = ListaDoble->new();
my $lista_prov = ListaCircularDoble->new();
my $matriz     = MatrizDispersa->new();

my $login_window;

sub abrir_panel_admin {
    $login_window->{ventana}->hide() if defined $login_window;
    PanelAdmin->nuevo(
        avl        => $avl,
        bst        => $bst,
        arbol_b    => $arbol_b,
        lista_med  => $lista_med,
        lista_prov => $lista_prov,
        matriz     => $matriz,
        cb_logout  => \&volver_login,
    );
}

sub abrir_panel_usuario {
    my ($usuario) = @_;
    $login_window->{ventana}->hide() if defined $login_window;
    PanelUsuario->nuevo(
        usuario   => $usuario,
        avl       => $avl,
        bst       => $bst,
        arbol_b   => $arbol_b,
        lista_med => $lista_med,
        cb_logout => \&volver_login,
    );
}

sub volver_login {
    $login_window->{ventana}->show_all();
}

$login_window = VentanaLogin->nueva(
    $avl,
    \&abrir_panel_admin,
    \&abrir_panel_usuario,
);

Gtk3::main();