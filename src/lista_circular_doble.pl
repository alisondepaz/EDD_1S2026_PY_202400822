our $lista_solicitudes = undef;

sub nuevo_nodo_solicitud {
    my ($num, $depto, $medicamento, $cantidad, $prioridad) = @_;
    return {
        num_solicitud => $num,
        departamento  => $depto,
        medicamento   => $medicamento,
        cantidad      => $cantidad,
        prioridad     => $prioridad,
        estado        => "PENDIENTE",
        ant           => undef,
        sig           => undef,
    };
}

sub insertar_solicitud {
    my ($depto, $medicamento, $cantidad, $prioridad) = @_;
    my $num  = sprintf("SOL-%03d", $contador_solicitud++);
    my $nodo = nuevo_nodo_solicitud($num, $depto, $medicamento, $cantidad, $prioridad);

    if (!defined $lista_solicitudes) {
        $nodo->{sig}        = $nodo;
        $nodo->{ant}        = $nodo;
        $lista_solicitudes  = $nodo;
    } else {
        my $primero = $lista_solicitudes;
        my $ultimo  = $primero->{ant};

        $ultimo->{sig}    = $nodo;
        $nodo->{ant}      = $ultimo;
        $nodo->{sig}      = $primero;
        $primero->{ant}   = $nodo;
    }

    print "\n  [OK] Solicitud $num registrada. Estado: PENDIENTE\n";
    return $num;
}

sub buscar_solicitud {
    my ($num) = @_;
    return undef unless defined $lista_solicitudes;
    my $actual = $lista_solicitudes;
    do {
        return $actual if ($actual->{num_solicitud} eq $num);
        $actual = $actual->{sig};
    } while ($actual != $lista_solicitudes);
    return undef;
}

sub eliminar_solicitud {
    my ($num) = @_;
    my $nodo = buscar_solicitud($num);
    return unless defined $nodo;
    
    if ($nodo->{sig} == $nodo) {
        $lista_solicitudes = undef;
        return;
    }

    $nodo->{ant}{sig} = $nodo->{sig};
    $nodo->{sig}{ant} = $nodo->{ant};
    $lista_solicitudes = $nodo->{sig} if ($nodo == $lista_solicitudes);
}

sub contar_solicitudes {
    return 0 unless defined $lista_solicitudes;
    my $actual = $lista_solicitudes;
    my $n = 0;
    do {
        $n++;
        $actual = $actual->{sig};
    } while ($actual != $lista_solicitudes);
    return $n;
}

sub crear_solicitud_reabastecimiento {
    my ($departamento) = @_;
    print "\n--- Nueva Solicitud de Reabastecimiento ---\n";
    print "  Departamento    : $departamento\n";
    print "  Medicamento     : ";
    my $med = <STDIN>; chomp $med;

    if ($med eq "") {
        print "\n  [!] El nombre del medicamento es obligatorio.\n";
        return;
    }

    print "  Cantidad a pedir: ";
    my $cant = <STDIN>; chomp $cant;

    unless ($cant =~ /^\d+$/ && $cant > 0) {
        print "\n  [!] La cantidad debe ser un numero entero mayor a cero.\n";
        return;
    }

    print "  Prioridad [ALTA/MEDIA/BAJA]: ";
    my $prio = <STDIN>; chomp $prio;
    $prio = uc($prio);

    unless ($prio eq "ALTA" || $prio eq "MEDIA" || $prio eq "BAJA") {
        print "\n  [AVISO] Prioridad no reconocida. Se asignara MEDIA.\n";
        $prio = "MEDIA";
    }

    insertar_solicitud($departamento, $med, $cant+0, $prio);
}

sub ver_solicitudes_pendientes {
    if (!defined $lista_solicitudes) {
        print "\n  [INFO] No hay solicitudes pendientes.\n";
        return;
    }
    my $total = contar_solicitudes();

    print "\n" . "=" x 65 . "\n";
    print "  SOLICITUDES PENDIENTES\n";
    print "  Total: $total solicitudes\n";
    print "=" x 65 . "\n";
    printf "  %-10s %-15s %-16s %5s %-6s\n", "Num", "Departamento", "Medicamento", "Cant", "Prior";
    print "-" x 65 . "\n";

    my $actual = $lista_solicitudes;
    do {
        printf "  %-10s %-15s %-16s %5d %-6s\n",
            $actual->{num_solicitud},
            $actual->{departamento},
            $actual->{medicamento},
            $actual->{cantidad},
            $actual->{prioridad};
        $actual = $actual->{sig};
    } while ($actual != $lista_solicitudes);

    print "=" x 65 . "\n";
}

sub ver_mis_solicitudes {
    my ($departamento) = @_;
    if (!defined $lista_solicitudes) {
        print "\n  [INFO] No hay solicitudes registradas.\n";
        return;
    }

    print "\n--- Solicitudes del departamento: $departamento ---\n";
    my $actual    = $lista_solicitudes;
    my $encontro  = 0;

    do {
        if (lc($actual->{departamento}) eq lc($departamento)) {
            printf "  [%s] %s | %d uds | Prioridad: %s\n",
                $actual->{num_solicitud},
                $actual->{medicamento},
                $actual->{cantidad},
                $actual->{prioridad};
            $encontro = 1;
        }
        $actual = $actual->{sig};
    } while ($actual != $lista_solicitudes);

    print "  No se encontraron solicitudes.\n" unless $encontro;
}

sub procesar_solicitud {
    ver_solicitudes_pendientes();
    return unless defined $lista_solicitudes;
    
    print "\n  Numero de solicitud a procesar: ";
    my $num = <STDIN>; chomp $num;

    my $nodo = buscar_solicitud($num);
    unless (defined $nodo) {
        print "\n  [!] Solicitud '$num' no encontrada.\n";
        return;
    }

    print "  Accion [APROBAR/RECHAZAR]: ";
    my $accion = <STDIN>; chomp $accion;
    $accion = uc($accion);

    if ($accion eq "APROBAR") {
        my $med_nodo = buscar_nodo_inventario_por_nombre($nodo->{medicamento});
        if (defined $med_nodo) {
            $med_nodo->{cantidad} += $nodo->{cantidad};
            print "\n  [OK] Inventario actualizado. Nuevo stock: $med_nodo->{cantidad}\n";
            registrar_historial("REABASTECIMIENTO", $med_nodo->{codigo}, $med_nodo->{nombre}, $nodo->{cantidad});
        } else {
            print "\n  [AVISO] Medicamento no encontrado en inventario.\n";
        }
        eliminar_solicitud($num);
        print "  [OK] Solicitud $num APROBADA.\n";

    } elsif ($accion eq "RECHAZAR") {
        eliminar_solicitud($num);
        print "\n  [OK] Solicitud $num RECHAZADA.\n";

    } else {
        print "\n  [!] Accion no valida.\n";
    }
}

1;