use strict;
use warnings;
use utf8;

binmode(STDOUT, ':utf8');
binmode(STDIN,  ':utf8');

BEGIN {
    mkdir("./datos") unless -d "./datos";
    mkdir("./datos/entrada") unless -d "./datos/entrada";
    mkdir("./reportes") unless -d "./reportes";
}

require './src/utilidades.pl';
require './src/lista_enlazada.pl';
require './src/matriz_dispersa.pl';
require './src/lista_doble.pl';
require './src/lista_circular_doble.pl';
require './src/lista_circular_listas.pl';
require './src/carga_csv.pl';
require './src/reportes.pl';

our $lista_inventario    = undef;
our $lista_solicitudes   = undef;
our $lista_historial     = undef;
our $lista_proveedores   = undef;
our $cabecera_filas      = undef;
our $cabecera_cols       = undef;
our $contador_solicitud  = 1;

sub main {
    mostrar_bienvenida();
    
    if (-e "./datos/entrada/prueba_f1.csv") {
        print "\n[INFO] Archivo de prueba detectado. Cargando inventario...\n";
        cargar_csv("./datos/entrada/prueba_f1.csv");
        print "[OK]   Inventario cargado correctamente.\n";
        pausar();
    }
    
    menu_principal();
}

sub menu_principal {
    my $op = "";
    while (1) {
        print "\n" . "=" x 50 . "\n";
        print "       SISTEMA FARMACEUTICO HOSPITALARIO\n";
        print "=" x 50 . "\n";
        print "  Seleccione su rol de acceso:\n";
        print "  [1] Administrador del sistema\n";
        print "  [2] Usuario departamental\n";
        print "  [0] Salir del sistema\n";
        print "-" x 50 . "\n";
        print "  Opcion: ";
        
        chomp($op = <STDIN>);
        
        if    ($op eq "1") { menu_administrador(); }
        elsif ($op eq "2") { menu_usuario();        }
        elsif ($op eq "0") { despedirse(); last;    }
        else               { print "\n[!] Opcion no valida.\n"; }
    }
}

sub menu_administrador {
    my $op = "";
    while (1) {
        print "\n" . "=" x 50 . "\n";
        print "            MENU - ADMINISTRADOR\n";
        print "=" x 50 . "\n";
        print "  -- Gestion de Medicamentos --\n";
        print "  [1]  Cargar inventario desde CSV\n";
        print "  [2]  Agregar medicamento\n";
        print "  [3]  Modificar medicamento\n";
        print "  [4]  Eliminar medicamento\n";
        print "  [5]  Buscar medicamento\n";
        print "  [6]  Ver inventario completo\n";
        print "  [7]  Consultar por laboratorio/medicamento\n";
        print "  -- Gestion de Solicitudes --\n";
        print "  [8]  Ver solicitudes pendientes\n";
        print "  [9]  Aprobar o rechazar solicitud\n";
        print "  -- Gestion de Proveedores --\n";
        print "  [10] Registrar proveedor\n";
        print "  [11] Registrar entrega de proveedor\n";
        print "  -- Reportes Graficos (Graphviz) --\n";
        print "  [12] Reporte lista doble enlazada\n";
        print "  [13] Reporte lista circular doble\n";
        print "  [14] Reporte lista circular de listas\n";
        print "  [15] Reporte matriz dispersa\n";
        print "  [16] Reporte historial de movimientos\n";
        print "  [0]  Volver al menu principal\n";
        print "-" x 50 . "\n";
        print "  Opcion: ";
        
        chomp($op = <STDIN>);
        
        if    ($op eq "1")  { cargar_csv_manual();           }
        elsif ($op eq "2")  { agregar_medicamento();         }
        elsif ($op eq "3")  { modificar_medicamento();       }
        elsif ($op eq "4")  { eliminar_medicamento();        }
        elsif ($op eq "5")  { buscar_medicamento();          }
        elsif ($op eq "6")  { mostrar_inventario_completo(); }
        elsif ($op eq "7")  { consultar_matriz_dispersa();   }
        elsif ($op eq "8")  { ver_solicitudes_pendientes();  }
        elsif ($op eq "9")  { procesar_solicitud();          }
        elsif ($op eq "10") { registrar_proveedor();         }
        elsif ($op eq "11") { registrar_entrega_proveedor(); }
        elsif ($op eq "12") { generar_reporte_lista_doble(); }
        elsif ($op eq "13") { generar_reporte_circ_doble();  }
        elsif ($op eq "14") { generar_reporte_circ_listas(); }
        elsif ($op eq "15") { generar_reporte_matriz();      }
        elsif ($op eq "16") { generar_reporte_historial();   }
        elsif ($op eq "0")  { last;                          }
        else                { print "\n[!] Opcion no valida.\n"; }
        
        pausar() if ($op ne "0");
    }
}

sub menu_usuario {
    print "\n--- Inicio de Sesion Usuario ---\n";
    print "  Codigo Departamento: ";
    my $depto = <STDIN>; chomp $depto;
    print "  Contrasena: ";
    my $pass = <STDIN>; chomp $pass;
    
    if ($pass ne "1234") {
        print "\n[!] Contrasena incorrecta. Volviendo al menu.\n";
        pausar();
        return;
    }
    
    $depto = "Departamento General" if ($depto eq "");
    
    my $op = "";
    while (1) {
        print "\n" . "=" x 50 . "\n";
        print "   USUARIO: $depto\n";
        print "=" x 50 . "\n";
        print "  [1] Ver inventario disponible\n";
        print "  [2] Solicitar reabastecimiento\n";
        print "  [3] Consultar mis solicitudes\n";
        print "  [4] Buscar medicamento\n";
        print "  [0] Volver al menu principal\n";
        print "-" x 50 . "\n";
        print "  Opcion: ";
        
        chomp($op = <STDIN>);
        
        if    ($op eq "1") { consultar_inventario();                  }
        elsif ($op eq "2") { crear_solicitud_reabastecimiento($depto); }
        elsif ($op eq "3") { ver_mis_solicitudes($depto);             }
        elsif ($op eq "4") { buscar_medicamento();                    }
        elsif ($op eq "0") { last;                                    }
        else               { print "\n[!] Opcion no valida.\n";       }
        
        pausar() if ($op ne "0");
    }
}

sub consultar_matriz_dispersa {
    print "\n--- Consulta de Matriz Dispersa ---\n";
    print "  [1] Consultar por medicamento (ver laboratorios)\n";
    print "  [2] Consultar por laboratorio (ver medicamentos)\n";
    print "  Opcion: ";
    my $op = <STDIN>; chomp $op;
    
    if ($op eq "1") {
        print "  Nombre del medicamento: ";
        my $med = <STDIN>; chomp $med;
        consultar_por_medicamento($med);
    } elsif ($op eq "2") {
        print "  Nombre del laboratorio: ";
        my $lab = <STDIN>; chomp $lab;
        consultar_por_laboratorio($lab);
    } else {
        print "\n[!] Opcion no valida.\n";
    }
}

sub mostrar_bienvenida {
    print "\n" . "*" x 50 . "\n";
    print "*   SISTEMA DE INVENTARIO FARMACEUTICO USAC    *\n";
    print "*        Hospital Universitario 2026           *\n";
    print "*" x 50 . "\n";
    print "\nIniciando sistema...\n";
    sleep(1);
}

sub despedirse {
    print "\n" . "-" x 50 . "\n";
    print "  Sistema cerrado. Hasta luego.\n";
    print "  Universidad de San Carlos de Guatemala.\n";
    print "-" x 50 . "\n";
}

main();