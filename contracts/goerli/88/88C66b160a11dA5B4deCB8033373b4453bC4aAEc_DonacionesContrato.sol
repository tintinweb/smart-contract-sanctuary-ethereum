// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract DonacionesContrato {
    struct ProductoDonadoRequest {
        uint idProducto;
        string descripcionProducto;
        uint cantidad;
    }

    struct ProductoDonado {
        uint idProducto;
        string descripcionProducto;
        uint cantidad;
        EstadoDonacion estado;
        uint timestamp;
    }

    struct ProductoDonadoResponse {
        uint idProducto;
        string descripcionProducto;
        uint cantidad;
        string estado;
        uint timestamp;
    }

    enum EstadoDonacion {
        PROCESADO,
        RESERVADO,
        ENTRANSITO,
        CONFIRMADOORG,
        ENTREGADO,
        CANCELADO
    }
    
    struct DonacionRequest {
        uint idDonacion;
        uint idOrganizacion;
        string organizacion;
        uint idCampania;
        string campania;
        uint idDonador;
        ProductoDonadoRequest[] productosDonados;
    }

    struct Donacion {
        uint idDonacion;
        uint idOrganizacion;
        string organizacion;
        uint idCampania;
        string campania;
        uint idDonador;
        ProductoDonado[] productosDonados;
        uint timestamp;
    }

    struct DonacionResponse {
        uint idDonacion;
        string organizacion;
        string campania;
        ProductoDonadoResponse[] productosDonados;
        uint timestamp;
    }

    struct DonacionConIndex {
        Donacion donacion;
        uint index;
    }

    struct DonacionHistorico {
        uint idDonacion;
        uint idProducto;
        EstadoDonacion estado;
        uint timestamp;
    }

    event datosDonacion (
        DonacionResponse response
    );

    modifier chequearModificador() {
        require(owner == msg.sender, "No esta autorizado a modificar los datos dentro del contrato");
        _;
    }

    Donacion[] private donaciones;
    DonacionHistorico[] private donacionesHistorico;
    address private owner;
    mapping (EstadoDonacion => string) estados;

    constructor(){
        owner = msg.sender;
        estados[EstadoDonacion.PROCESADO] = "PROCESADO";
        estados[EstadoDonacion.RESERVADO] = "RESERVADO";
        estados[EstadoDonacion.ENTRANSITO] = "ENTRANSITO";
        estados[EstadoDonacion.CONFIRMADOORG] = "CONFIRMADOORG";
        estados[EstadoDonacion.ENTREGADO] = "ENTREGADO";
        estados[EstadoDonacion.CANCELADO] = "CANCELADO";
    }

    function crearResponse(Donacion memory donacion) private view returns (DonacionResponse memory response) {
        ProductoDonado[] memory listaOriginal = donacion.productosDonados;
        ProductoDonadoResponse[] memory productosResponse = new ProductoDonadoResponse[](listaOriginal.length);
        for (uint256 i = 0; i < listaOriginal.length; i++) {
            ProductoDonadoResponse memory prodResponse = ProductoDonadoResponse(listaOriginal[i].idProducto, listaOriginal[i].descripcionProducto, listaOriginal[i].cantidad, estados[listaOriginal[i].estado], listaOriginal[i].timestamp);
            productosResponse[i] = prodResponse;
        }

        response = DonacionResponse(donacion.idDonacion, donacion.organizacion, donacion.campania, productosResponse, donacion.timestamp);
    }

    function chequearExistencia(DonacionRequest memory donacion) private view {
        for (uint256 i = 0; i < donaciones.length; i++) {
            if(donaciones[i].idDonacion == donacion.idDonacion){
                revert("Ya existe una donacion con el id asignado");
            }
        }
    }

    function crearDonacion(DonacionRequest memory request) public chequearModificador {
        chequearExistencia(request);
        uint timestamp = block.timestamp;
        Donacion storage nuevaDonacion = donaciones.push();

        nuevaDonacion.idDonacion = request.idDonacion;
        nuevaDonacion.idOrganizacion = request.idOrganizacion;
        nuevaDonacion.organizacion = request.organizacion;
        nuevaDonacion.idCampania = request.idCampania;
        nuevaDonacion.campania = request.campania;
        nuevaDonacion.idDonador = request.idDonador;
        nuevaDonacion.timestamp = timestamp;

        for (uint256 i = 0; i < request.productosDonados.length; i++) {
            ProductoDonadoRequest memory productoRequest = request.productosDonados[i];
            uint idProducto = productoRequest.idProducto;
            string memory descripcionProducto = productoRequest.descripcionProducto;
            uint cantidad = productoRequest.cantidad;
            ProductoDonado memory productoDonado = ProductoDonado(idProducto, descripcionProducto, cantidad, EstadoDonacion.PROCESADO, timestamp);
            nuevaDonacion.productosDonados.push(productoDonado);

            DonacionHistorico storage nuevaDonacionHistorico = donacionesHistorico.push();
            nuevaDonacionHistorico.idDonacion = request.idDonacion;
            nuevaDonacionHistorico.idProducto = request.productosDonados[i].idProducto;
            nuevaDonacionHistorico.estado = EstadoDonacion.PROCESADO;
            nuevaDonacionHistorico.timestamp = timestamp;
        }

        DonacionResponse memory response = crearResponse(nuevaDonacion);
        emit datosDonacion(response);
    }

    function consultarTodasLasDonaciones() public view returns (DonacionResponse[] memory){
        DonacionResponse[] memory lista = new DonacionResponse[](donaciones.length);
        for (uint256 i = 0; i < donaciones.length; i++) {
            lista[i] = crearResponse(donaciones[i]);
        }
        return lista;
    }

    function consultarHistorialDonaciones() public view returns (DonacionHistorico[] memory){
        DonacionHistorico[] memory lista = new DonacionHistorico[](donacionesHistorico.length);
        for (uint256 i = 0; i < donacionesHistorico.length; i++) {
            lista[i] = donacionesHistorico[i];
        }
        return lista;
    }

    function consultarDonacionesPorId(uint idDonacion) public view returns (DonacionResponse memory){
        for (uint256 i = 0; i < donaciones.length; i++) {
            if(donaciones[i].idDonacion == idDonacion){
                return crearResponse(donaciones[i]);
            }
        }
        revert("No se encontro la donacion con el id ingresado");
    }

    function consultarDonacionesPorOrganizacion(uint idOrganizacion) public view returns (DonacionResponse[] memory) {
        Donacion[] memory listaFiltrada = new Donacion[](donaciones.length);
        uint contador = 0;
        for (uint256 i = 0; i < donaciones.length; i++) {
            Donacion memory request = donaciones[i];
            if(request.idOrganizacion == idOrganizacion){
                listaFiltrada[contador] = donaciones[i];
                contador++;
            }
        }

        DonacionResponse[] memory lista = new DonacionResponse[](contador);

        for (uint256 i = 0; i < contador; i++) {
            lista[i] = crearResponse(listaFiltrada[i]);
        }

        return lista;
    }

    function traerDatosDeDonacion(uint idDonacion) private view returns (DonacionConIndex memory){
        for (uint256 i = 0; i < donaciones.length; i++) {
            if(donaciones[i].idDonacion == idDonacion){
                return DonacionConIndex(donaciones[i], i);
            }
        }

        revert("No se encontro la donacion con el id ingresado");
    }

    function cambiarEstadoDeDonacion(uint idDonacion, uint idProducto) public {
        DonacionConIndex memory donacion = traerDatosDeDonacion(idDonacion);
        ProductoDonado[] memory lista = donacion.donacion.productosDonados;
        uint timestamp = block.timestamp;

        for (uint256 i = 0; i < lista.length; i++) {
            if(lista[i].idProducto == idProducto){
                donaciones[donacion.index].productosDonados[i].estado = EstadoDonacion(uint(lista[i].estado) + 1);
                donaciones[donacion.index].productosDonados[i].timestamp = timestamp;

                DonacionHistorico storage nuevaDonacionHistorico = donacionesHistorico.push();
                nuevaDonacionHistorico.idProducto = lista[i].idProducto;
                nuevaDonacionHistorico.estado = EstadoDonacion(uint(lista[i].estado) + 1);
                nuevaDonacionHistorico.timestamp = timestamp;
                return;
            }
        }

        revert("No se encontro el producto donado con el id recibido");
    }

    function cancelarDonacion(uint idDonacion, uint idProducto) public {
        DonacionConIndex memory donacion = traerDatosDeDonacion(idDonacion);
        ProductoDonado[] memory lista = donacion.donacion.productosDonados;
        uint timestamp = block.timestamp;

        for (uint256 i = 0; i < lista.length; i++) {
            if(lista[i].idProducto == idProducto){
                donaciones[donacion.index].productosDonados[i].estado = EstadoDonacion.CANCELADO;
                donaciones[donacion.index].productosDonados[i].timestamp = timestamp;

                DonacionHistorico storage nuevaDonacionHistorico = donacionesHistorico.push();
                nuevaDonacionHistorico.idProducto = lista[i].idProducto;
                nuevaDonacionHistorico.estado = EstadoDonacion.CANCELADO;
                nuevaDonacionHistorico.timestamp = timestamp;
                return;
            }
        }

        revert("No se encontro el producto donado con el id recibido");
    }
}