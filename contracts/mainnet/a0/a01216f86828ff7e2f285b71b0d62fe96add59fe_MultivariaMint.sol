// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.13;

import "./IERC1155.sol";
import "./Multivaria.sol";

contract MultivariaMint{
    uint256 public _collectorPrice = 0.05 ether;
    uint256 public _publicPrice = 0.08 ether;
    uint256 public _maxSupply = 192;
    uint256 public _supply = 1;

    address public _multivariaAddress;
    address public _signer;
    address public _recipient;

    bool public _ALMintOpened;
    bool public _publicMintOpened;

    mapping(address => bool) public _isAdmin;
    mapping(address => uint256) public _ALTokensMinted;
    mapping(address => uint256) public _publicTokenMinted;

    constructor(){
        _isAdmin[msg.sender]=true;
    }

    function setPublicMintPrice (uint256 publicMintPrice) external{
        require(_isAdmin[msg.sender], "Only Admins can set the public price");
        _publicPrice = publicMintPrice;
    }

    function setALMintPrice (uint256 ALMintPrice) external{
        require(_isAdmin[msg.sender], "Only Admins can set the AL price");
        _collectorPrice = ALMintPrice;
    }
    
    function setSigner (address signer) external{
        require(_isAdmin[msg.sender], "Only Admins can set signer");
        _signer = signer;
    }

    function setMultivariaAddress(address multivariaAddress) external{
        require(_isAdmin[msg.sender], "Only Admins can set Multivaria Address");
        _multivariaAddress = multivariaAddress;
    }

    function setRecipient(address recipient) external{
        require(_isAdmin[msg.sender], "Only Admins can set the recipient");
        _recipient = recipient;
    }

    function toggleALMintOpened() external{
        require(_isAdmin[msg.sender], "Only Admins can toggle AL Mint");
        _ALMintOpened = !_ALMintOpened;
    }

    function togglePublicMintOpened() external{
        require(_isAdmin[msg.sender], "Only Admins can toggle burn Mint");
        _publicMintOpened = !_publicMintOpened;
    }

    function adjustSupply(uint256 supply) external{
        require(_isAdmin[msg.sender], "Only Admins can toggle burn Mint");
        _supply = supply;
    }

    function mintAllowed(uint256 quantity, uint8 v, bytes32 r, bytes32 s)internal view returns(bool){
        return(
            _signer ==
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            keccak256(
                                abi.encodePacked(
                                    msg.sender,
                                    _multivariaAddress,
                                    _ALMintOpened,
                                    _publicPrice,
                                    _ALTokensMinted[msg.sender] + quantity <= 2
                                )
                            )
                        )
                    )
                , v, r, s)
        );
    }

    function collectorMintAllowed(uint256 quantity, uint8 v, bytes32 r, bytes32 s)internal view returns(bool){
        return(
            _signer ==
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            keccak256(
                                abi.encodePacked(
                                    msg.sender,
                                    _multivariaAddress,
                                    _ALMintOpened,
                                    _collectorPrice,
                                    _ALTokensMinted[msg.sender] + quantity <= 2
                                )
                            )
                        )
                    )
            , v, r, s)
        );
    }


    function ALMint(
        uint8 v,
        bytes32 r, 
        bytes32 s,
        uint256 quantity
    ) external payable{
        require(mintAllowed(quantity, v, r, s), "Mint not allowed");
        require(msg.value >= _publicPrice * quantity, "Not enough funds");
        require(_supply + quantity <= _maxSupply,"Max supply reached");
        payable(_recipient).transfer(_publicPrice * quantity);
        Multivaria(_multivariaAddress).mint(msg.sender, 12, quantity);
        Multivaria(_multivariaAddress).mint(msg.sender, 13, quantity);
        _supply += quantity;
        _ALTokensMinted[msg.sender] += quantity;
    }

    function collectorMint(
        uint8 v,
        bytes32 r, 
        bytes32 s,
        uint256 quantity
    ) external payable{
        require(collectorMintAllowed(quantity, v, r, s), "Mint not allowed");
        require(msg.value >= _collectorPrice * quantity, "Not enough funds");
        require(_supply + quantity <= _maxSupply,"Max supply reached");
        payable(_recipient).transfer(_collectorPrice * quantity);
        Multivaria(_multivariaAddress).mint(msg.sender, 12, quantity);
        Multivaria(_multivariaAddress).mint(msg.sender, 13, quantity);
        _supply += quantity;
        _ALTokensMinted[msg.sender] += quantity;
    }

    function publicMint(uint256 quantity)external payable{
        require(_publicMintOpened, "Public mint is currently closed");
        require(_publicTokenMinted[msg.sender] + quantity <= 2, "User already minted the max number of pieces");
        require(_supply + quantity <= _maxSupply,"Max supply reached");
        require(msg.value >= _publicPrice * quantity, "Not enough funds");
        payable(_recipient).transfer(_publicPrice * quantity);
        Multivaria(_multivariaAddress).mint(msg.sender, 12, quantity);
        Multivaria(_multivariaAddress).mint(msg.sender, 13, quantity);
        _supply += quantity;
        _publicTokenMinted[msg.sender] += quantity;
    }
}