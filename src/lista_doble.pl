our $lista_inventario = undef;

sub nuevo_nodo_medicamento {
    my ($codigo, $nombre, $pa, $lab, $precio, $cant, $fecha, $min) = @_;
    return {
        codigo            => $codigo,
        nombre            => $nombre,
        principio_activo  => $pa,
        laboratorio       => $lab,
        precio_unitario   => $precio,
        cantidad          => $cant,
        fecha_vencimiento => $fecha,
        nivel_minimo      => $min,
        ant               => undef,
        sig               => undef,
    };
}

sub insertar_medicamento {
    my ($codigo, $nombre, $pa, $lab, $precio, $cant, $fecha, $min) = @_;
    
    if (defined buscar_nodo_inventario($codigo)) {
        print "\n[AVISO] El medicamento con codigo '$codigo' ya existe.\n";
        return;
    }
    
    my $nodo = nuevo_nodo_medicamento($codigo, $nombre, $pa, $lab, $precio, $cant, $fecha, $min);
    
    if (!defined $lista_inventario) {
        $lista_inventario = $nodo;
    } else {
        my $actual = $lista_inventario;
        while (defined $actual->{sig}) {
            $actual = $actual->{sig};
        }
        $actual->{sig} = $nodo;
        $nodo->{ant}   = $actual;
    }
    
    registrar_historial("INSERCION", $codigo, $nombre, $cant);
    actualizar_matriz_precio($lab, $nombre, $precio, $pa, $cant);
}

sub buscar_nodo_inventario {
    my ($codigo) = @_;
    my $actual = $lista_inventario;
    while (defined $actual) {
        return $actual if (lc($actual->{codigo}) eq lc($codigo));
        $actual = $actual->{sig};
    }
    return undef;
}

sub buscar_nodo_inventario_por_nombre {
    my ($nombre) = @_;
    my $actual = $lista_inventario;
    while (defined $actual) {
        return $actual if (index(lc($actual->{nombre}), lc($nombre)) >= 0);
        $actual = $actual->{sig};
    }
    return undef;
}

sub buscar_medicamento {
    print "\n--- Buscar Medicamento ---\n";
    print "  Ingrese el codigo: ";
    my $cod = <STDIN>; chomp $cod;
    my $nodo = buscar_nodo_inventario($cod);
    if (defined $nodo) { imprimir_medicamento($nodo); } 
    else { print "\n  [!] No se encontro el medicamento.\n"; }
}

sub imprimir_medicamento {
    my ($n) = @_;
    my $alerta = ($n->{cantidad} <= $n->{nivel_minimo}) ? "   <<< STOCK BAJO >>> " : "";
    print "\n  +-------------------------------------------------+\n";
    print "  Codigo           : $n->{codigo}\n";
    print "  Nombre           : $n->{nombre}\n";
    print "  Laboratorio      : $n->{laboratorio}\n";
    print "  Precio           : Q $n->{precio_unitario}\n";
    print "  Cantidad         : $n->{cantidad}$alerta\n";
    print "  Vencimiento      : $n->{fecha_vencimiento}\n";
    print "  +-------------------------------------------------+\n";
}

sub consultar_inventario {
    if (!defined $lista_inventario) { print "\n  [INFO] Inventario vacio.\n"; return; }
    print "\n" . "=" x 73 . "\n";
    printf "  %-8s %-18s %-16s %-12s %7s %6s\n", "Codigo", "Nombre", "Principio", "Laboratorio", "Precio", "Stock";
    print "-" x 73 . "\n";
    
    my $actual = $lista_inventario;
    while (defined $actual) {
        my $flag = ($actual->{cantidad} <= $actual->{nivel_minimo}) ? "* " : "  ";
        printf "  %-8s %-18s %-16s %-12s %7.2f %5d%s\n", 
            $actual->{codigo}, $actual->{nombre}, $actual->{principio_activo},
            $actual->{laboratorio}, $actual->{precio_unitario}, $actual->{cantidad}, $flag;
        $actual = $actual->{sig};
    }
    print "=" x 73 . "\n  (*) Indica stock bajo el minimo\n";
}

sub mostrar_inventario_completo { consultar_inventario(); }

sub agregar_medicamento {
    print "\n--- Agregar Medicamento ---\n";
    print "  Codigo: "; my $cod = <STDIN>; chomp $cod;
    print "  Nombre: "; my $nom = <STDIN>; chomp $nom;
    print "  Principio: "; my $pa = <STDIN>; chomp $pa;
    print "  Laboratorio: "; my $lab = <STDIN>; chomp $lab;
    print "  Precio: "; my $prec = <STDIN>; chomp $prec;
    print "  Cantidad: "; my $cant = <STDIN>; chomp $cant;
    print "  Vencimiento: "; my $fecha = <STDIN>; chomp $fecha;
    print "  Nivel Minimo: "; my $min = <STDIN>; chomp $min;
    
    if ($cod eq "" || $nom eq "") { print "\n  [!] Campos obligatorios vacios.\n"; return; }
    insertar_medicamento($cod, $nom, $pa, $lab, $prec+0, $cant+0, $fecha, $min+0);
    print "\n  [OK] Medicamento agregado.\n";
}

sub modificar_medicamento {
    print "\n--- Modificar Medicamento ---\n";
    print "  Codigo a modificar: "; my $cod = <STDIN>; chomp $cod;
    my $nodo = buscar_nodo_inventario($cod);
    unless (defined $nodo) { print "\n  [!] No encontrado.\n"; return; }
    
    imprimir_medicamento($nodo);
    print "\n  Deje en blanco para no cambiar.\n";
    
    print "  Nuevo Nombre [$nodo->{nombre}]: "; my $v = <STDIN>; chomp $v; $nodo->{nombre} = $v if $v ne "";
    print "  Nuevo Precio [$nodo->{precio_unitario}]: "; $v = <STDIN>; chomp $v; $nodo->{precio_unitario} = $v+0 if $v ne "";
    print "  Nueva Cantidad [$nodo->{cantidad}]: "; $v = <STDIN>; chomp $v; $nodo->{cantidad} = $v+0 if $v ne "";
    
    registrar_historial("MODIFICACION", $cod, $nodo->{nombre}, $nodo->{cantidad});
    print "\n  [OK] Actualizado.\n";
}

sub eliminar_medicamento {
    print "\n--- Eliminar Medicamento ---\n";
    print "  Codigo: "; my $cod = <STDIN>; chomp $cod;
    my $nodo = buscar_nodo_inventario($cod);
    unless (defined $nodo) { print "\n  [!] No encontrado.\n"; return; }
    
    print "  Confirmar eliminacion de $nodo->{nombre} [s/n]: ";
    my $conf = <STDIN>; chomp $conf;
    return unless (lc($conf) eq "s");
    
    if (defined $nodo->{ant}) { $nodo->{ant}{sig} = $nodo->{sig}; } 
    else { $lista_inventario = $nodo->{sig}; }
    
    if (defined $nodo->{sig}) { $nodo->{sig}{ant} = $nodo->{ant}; }
    
    registrar_historial("ELIMINACION", $cod, $nodo->{nombre}, 0);
    print "\n  [OK] Eliminado.\n";
}

1;