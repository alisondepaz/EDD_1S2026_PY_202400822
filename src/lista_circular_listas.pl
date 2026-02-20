our $lista_proveedores = undef;

sub nuevo_nodo_proveedor {
    my ($nit, $nombre) = @_;
    return {
        nit             => $nit,
        nombre          => $nombre,
        primera_entrega => undef,
        sig             => undef,
    };
}

sub insertar_proveedor {
    my ($nit, $nombre) = @_;
    if (defined buscar_proveedor($nit)) {
        print "\n  [AVISO] El proveedor con NIT '$nit' ya esta registrado.\n";
        return;
    }

    my $nodo = nuevo_nodo_proveedor($nit, $nombre);

    if (!defined $lista_proveedores) {
        $nodo->{sig}     = $nodo;
        $lista_proveedores = $nodo;
    } else {
        my $actual = $lista_proveedores;
        while ($actual->{sig} != $lista_proveedores) {
            $actual = $actual->{sig};
        }
        $actual->{sig}   = $nodo;
        $nodo->{sig}     = $lista_proveedores;
    }

    print "\n  [OK] Proveedor '$nombre' (NIT: $nit) registrado.\n";
}

sub buscar_proveedor {
    my ($nit) = @_;
    return undef unless defined $lista_proveedores;
    my $actual = $lista_proveedores;
    do {
        return $actual if ($actual->{nit} eq $nit);
        $actual = $actual->{sig};
    } while ($actual != $lista_proveedores);
    return undef;
}

sub insertar_entrega_proveedor {
    my ($nit, $fecha, $factura, $medicamento, $cantidad) = @_;
    my $prov = buscar_proveedor($nit);
    unless (defined $prov) {
        print "\n  [!] No existe proveedor con NIT '$nit'.\n";
        return;
    }

    my $entrega = {
        fecha       => $fecha,
        num_factura => $factura,
        medicamento => $medicamento,
        cantidad    => $cantidad,
        sig         => undef,
    };

    if (!defined $prov->{primera_entrega}) {
        $prov->{primera_entrega} = $entrega;
    } else {
        my $e = $prov->{primera_entrega};
        while (defined $e->{sig}) { $e = $e->{sig}; }
        $e->{sig} = $entrega;
    }

    print "\n  [OK] Entrega registrada para '$prov->{nombre}'.\n";
}

sub registrar_proveedor {
    print "\n--- Registrar Proveedor ---\n";
    print "  NIT del proveedor   : ";
    my $nit = <STDIN>; chomp $nit;
    print "  Nombre del proveedor: ";
    my $nom = <STDIN>; chomp $nom;
    if ($nit eq "" || $nom eq "") {
        print "\n  [!] El NIT y el nombre son obligatorios.\n";
        return;
    }
    insertar_proveedor($nit, $nom);
}

sub registrar_entrega_proveedor {
    unless (defined $lista_proveedores) {
        print "\n  [INFO] No hay proveedores registrados.\n";
        return;
    }
    print "\n--- Registrar Entrega de Proveedor ---\n";
    print "  Proveedores registrados:\n";

    my $p = $lista_proveedores;
    do {
        print "    NIT: $p->{nit}  ->  $p->{nombre}\n";
        $p = $p->{sig};
    } while ($p != $lista_proveedores);

    print "\n  NIT del proveedor         : ";
    my $nit = <STDIN>; chomp $nit;
    print "  Fecha de entrega (AAAA-MM-DD): ";
    my $fecha = <STDIN>; chomp $fecha;
    print "  Numero de factura         : ";
    my $fac = <STDIN>; chomp $fac;
    print "  Medicamento entregado     : ";
    my $med = <STDIN>; chomp $med;
    print "  Cantidad entregada        : ";
    my $cant = <STDIN>; chomp $cant;

    unless ($cant =~ /^\d+$/ && $cant > 0) {
        print "\n  [!] La cantidad debe ser un entero positivo.\n";
        return;
    }

    insertar_entrega_proveedor($nit, $fecha, $fac, $med, $cant+0);
}

1;