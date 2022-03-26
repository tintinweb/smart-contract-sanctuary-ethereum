/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                            @@                               //    
//                                         @@@,,@@(                            //    
//                                     @@@@@@@@@,,#@@@@@@@@@                   //    
//                                @@@@@**,,,,,,,,,,,,,,,,,,,@@@@@              //    
//                           @@@@@**,,,,,,,,,,****,,,,,,,,,,,,,,,@@            //    
//                         @@***,,,,,,,@@@@@@@*******,,,,,@@@@***,,@@          //    
//                       @@**,,,,,,,@@@&&&&%%%@@@@#**,,,,,,,@@@@@,,@@          //    
//                    @@@,,,,,,,**@@%%%%%&&%%%%%%%&@@**,,,,,@@@@@**,,@@@       //    
//                  @@@@@**,,,,,@@%%%%%&&%%&&&%%%%%%%@@,,,,,@@%%%@@**@@@       //    
//                @@@@***,,,,@@@%%&&%%%&&%%&&&%%%%%%%@@***,,@@&&&%%@@          //    
//                @@@@***,,@@&&&&&&&&&&&&&&&&&&&%%%%%@@***@@%%&&&&&&&@@@       //    
//             @@@&&@@***@@@@&&&&&&&@@@@@@@@@@&&&&&&&@@***@@@@@@@@@&&@@@       //    
//             @@@@@@@***@@%%&&&@@@@(((///////@@@@@&&&&@@@@@/////**@@          //    
//           @@&&&&&&&@@@&&&&@@@%%((///***********#@@@@@@@%%//*******@@@       //    
//        (@@&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       //    
//      @@@&&&&@@@((((@@@@@&&###%%%%(((((*********,,,,,...  ,,,,,  **///       //    
//    @@@@@@@@@///**@@@@@**&&@@@((((**********,,,,...  ,,,,,  ***////(((       //    
// [email protected]@@@@&&@@///**@@%%%&&&&@@@%%((///****,,,,,..   *********/////(((((       //    
// [email protected]@&&&&&@@///**@@@@@**&&%%%@@%%(((/////////@@@@@@@///@@@@@@@**@@          //    
// [email protected]@@@@&&&&@@@////*******&&&%%@@@@@@@(((((((@@&%%@@(((@@##@@@**@@          //    
// @@@&&@@@@@@@&&&@@///////@@&&&&&&&&&&&&@@///(((((((////////////////@@@       //    
// @@@&&&&&&&&&@@@@@@@@@@@@&&&&&&&&&&&&@@/////***********************///@@     //    
// &&&&&&&&&&&&@@@@@@@&&&&&&&&&&&&&&@@@////*****************************@@     //    
// &&&&&@@&%%%%@@@%%%%%%%%%%%%%%&&&&@@@((//@@@@@@@@@@@@@@@@@@@@@@@@@@***@@     //    
// &&&&&&&&&&%%%%%%%%%%%%%%%%%%%&&@@@@@((//((((((((((//////////////((@@@       //    
// &&&&&&&&%%%%%%%%%%%&&&%%%%%%%&&&&@@@%%((//////////****************@@@       //    
// &&&&&%%&&&&&%%%&&%%%%%%%%%%%%&&@@@@@@@%%(((////*****************@@          //    
// @@@&&&&&@@%%&&&&&%%%%%&&&&%%%&&&&&&&&&@@(((///////////////////@@&&@@@       //    
// &&&&&&&&&&%%&&&&&%%%%%&&%%%%%&&&&%%%@@@@@@@@@@@@@@@@@@@@@@@@@@%%&&&&&@@     //    
// &&&&&&&&&&%%&&&&&&&%%%&&&&%%%&&%%%%%%%&&@@@@@@@@@@&&@@@&&&&%%%&&%%%%%&&@@   //    
// @@@&&&&&&&&&&&&&&%%&&&&&@@&&&&&%%%%%%%&&&&&@@&&&&&&&%%%&&%%%%%%%%%&&&%%@@   //    
// @@@&&&&&&&&&&&&%%&&@@@&&&&&&&&&&&&&&&&&&&&&&&%%%%%&&&&&%%%%%%%%%%%%%%&&&&@@@//    
/////////////////////////////////////////////////////////////////////////////////
//           ____             __        _        __ __                         //
//          / __ \___    ____/ /  ___ _(_)__    / //_/__  ___  ___ ____        //
//         / /_/ / _ \  / __/ _ \/ _ `/ / _ \  / ,< / _ \/ _ \/ _ `/_ /        //
//         \____/_//_/  \__/_//_/\_,_/_/_//_/ /_/|_|\___/_//_/\_, //__/        //
//         By: 0xInuarashi.eth                               /___/             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////

/*
    On Chain Kongz. Created by 0xInuarashi with <3 https://twitter.com/0xInuarashi

    100% On-Chain, Decoded from Kongz DNA, and recreated into groovy CyberKongz 
    that will live On-Chain forever.

    These are KongzBound NFTs that cannot be traded or transferred. 
    The owner of each token will always be the owner of the 
    Cyberkongz at https://opensea.io/collection/cyberkongz.
*/

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

interface iOCK {
    function tokenURI(uint256 tokenId_) external view returns (string memory);
}

interface iKongz {
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
    function balanceOf(address address_) external view returns (uint256); 
}

contract OnChainKongzGallery is Ownable {
    
    // Token Details
    string public name = "On Chain Kongz";
    string public symbol = "OCKONGZ";
    function setNameAndSymbol(string calldata name_, string calldata symbol_)
    external onlyOwner { name = name_; symbol = symbol_; }

    // Interface
    iOCK public OCK = iOCK(0x3Ce95E9aD8DCFBe45fc8267B83B3Ec188D792f40);
    function setOCK(address address_) external onlyOwner {
        OCK = iOCK(address_); }

    iKongz public Kongz = iKongz(0x57a204AA1042f6E66DD7730813f4024114d74f37);
    function setKongz(address address_) external onlyOwner {
        Kongz = iKongz(address_); }
    
    // Magic Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, 
        address indexed fromAddress, address indexed toAddress);

    // Magic Logic
    function totalSupply() public view returns (uint256) {
        return Kongz.totalSupply();
    }
    function ownerOf(uint256 tokenId_) public view returns (address) {
        return Kongz.ownerOf(tokenId_);
    }
    function balanceOf(address address_) public view returns (uint256) {
        return Kongz.balanceOf(address_);
    }

    // Token URI
    function tokenURI(uint256 tokenId_) public view returns (string memory) {
        return OCK.tokenURI(tokenId_);
    }

    // ERC721 OpenZeppelin Standard Stuff
    function supportsInterface(bytes4 interfaceId_) public pure returns (bool) {
        return (interfaceId_ == 0x80ac58cd || interfaceId_ == 0x5b5e139f);
    }

    // Initialization Methods
    function initialize(uint256 start_, uint256 end_) external onlyOwner {
        for (uint256 i = start_; i <= end_; i++) {
            emit Transfer(address(0), address(this), i);
        }
    }
    function initializeToOwners(uint256 start_, uint256 end_) external onlyOwner {
        for (uint256 i = start_; i <= end_; i++) {
            emit Transfer(address(0), Kongz.ownerOf(i), i);
        }
    }
    function initializeToCalldata(uint256 start_, uint256 end_, 
    address[] calldata addresses_) external onlyOwner {
        uint256 _length = start_ - end_ + 1;
        require(_length == addresses_.length,
            "Addresses length incorrect!");

        uint256 _index;
        for (uint256 i = start_; i <= end_; i++) {
            emit Transfer(address(0), addresses_[_index++], i);
        }
    }
    function initializeEIP2309(uint256 start_, uint256 end_) 
    external onlyOwner {
        emit ConsecutiveTransfer(start_, end_, address(0), address(this));
    }
    function initializeEIP2309ToTarget(uint256 start_, uint256 end_, address to_) 
    external onlyOwner {
        emit ConsecutiveTransfer(start_, end_, address(0), to_);
    }
}