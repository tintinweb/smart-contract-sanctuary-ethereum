pragma solidity ^0.8.0;

import "Ownable.sol";

contract Decentragram is Ownable {
    /*
    Que cosas voy a querer hacer?
    1- Postear una img
    2- Guardar archivos en la blockchain
    3- Tipear una imagen que pertenece a otro.
    Esto incluye una transferencia de una waller a otra
    
    Para eso, tenemos que definir que queremos de una imagen:
    - url de la imagen
    - tips realizados

    Y voy a tener que mantener el rastro de todos los posts realizados.
    Por lo tanto de alguna forma voy a tener que mapear Post -> su dueño. Tal vez
    con un mapa o con una lista de Posts es suficiente

    Tambien voy a tener que mantener un conteo de la cantidad de posts totales. Esto me sirve
    para cualquier cosa que quiera hacer. Si quiero filtrar por ejemplo o realizar
    alguna operacion de busqueda sobre el array / mapa o lo que fuera a utilizar.

    Otro detalle importante: como los tips van a ser en ether, necesito primero pasarlos a Wei
    y ahi hacer la transformacion a otra moneda por ejemplo dolares, si quiero mostrar
    cuantos dolares en total tiene o ether.
    */
    uint256 public postCount;
    struct Post {
        uint256 id;
        uint256 tips;
        string hash;
        string description;
        address payable owner;
    }
    Post[] public posts;

    event PostUploaded(
        uint256 id,
        uint256 tips,
        string hash,
        string description,
        address payable owner
    );

    event PostTipped(
        uint256 id,
        uint256 tips,
        string hash,
        string description,
        address payable owner
    );

    function uploadPost(string memory _imgHash, string memory _description)
        public
    {
        //Para asegurarse de que no me mandan cosas vacias
        require(bytes(_imgHash).length > 0);
        require(bytes(_description).length > 0);
        require(msg.sender != address(0));

        posts.push(
            Post(postCount, 0, _imgHash, _description, payable(msg.sender))
        );
        //Como comunicar al frontend que fue creado exitosamente? Mediante un evento
        emit PostUploaded(
            postCount,
            0,
            _imgHash,
            _description,
            payable(msg.sender)
        );
        postCount++;
    }

    function tipPost(uint256 _id) external payable {
        require(_id >= 0 && _id < postCount);
        Post memory post = posts[_id];

        post.owner.transfer(msg.value);

        post.tips += msg.value;
        posts[_id] = post;

        emit PostTipped(
            post.id,
            post.tips,
            post.hash,
            post.description,
            payable(msg.sender)
        );
    }
}

pragma solidity ^0.8.0;

contract Ownable {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }
}