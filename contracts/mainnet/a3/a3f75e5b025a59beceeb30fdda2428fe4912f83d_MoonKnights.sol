// ********************************************************************************
// *******************************************************************@@***********
// ******************************************************************@/************
// ****************************************************************@@@@******%/****
// ****************************************************************@@@@@@@@@@******
// ********************,,**********************************************@@@@********
// ********************@%*****************,,,,,,,**********************************
// ********************@%*************  ,,....... * *******************************
// ********************,,************ ,....   ....   ,*************,,**************
// ********************************** ,..            ,***********,,@@,,************
// ********************************* ,.    .          .****************************
// ******************************** ,.        ..   ,    ***************************
// ******************************* ,..    ... .,*,..    ***************************
// ********************************         ,.  . .,    ***************************
// ********************************                 *******************************
// *************************** ....        .....     ,*****************************
// ************@@************ .      &    &       &.  .****************.,**********
// ************@@*********** .  .*..  ./&...&....&...%% ***************************
// ************************ .                           ***************************
// ************************ .  ...    ...... .  // .    ***************************
// *********************** .            . .  .#@@@ .     **************************
// *********************** .              . . .. . .      *************************
// **************@@*****. .   ....                         ************************
// *********************,.,,  ....  ,,,, @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,***********
// ******************** ...              .  ......        *************************
// ******************** ...             .                ************,,**,,********
// ******************* ..             .  .       .   ..  **************@@**********
// ******************* ..            .   .       .   .. . *************************
// ****************** ..              ..         .   .. . *************************
// ****************** .                                 . *************************
// ******************      *******  ...   ***   ..  *.    *************************
// *******************************  ..   ****   ..   ,*****************************

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MoonKnights is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 3333;
    uint256 public price = 0.006 ether;
    uint256 public maxPerTx = 5;
    uint256 public maxFreeAmount = 1333;
    uint256 public maxFreePerWallet = 1;
    uint256 public maxFreePerTx = 1;
    string public baseURI =
        "ipfs://Qmb8L52Zxxhuuifp1y3r5sRwxd1jatarQZXC45eRZrGSGW/";
    bool public mintEnabled = true;
    mapping(address => uint256) private _mintedFreeAmount;

    constructor() ERC721A("MoonKnights", "MK") {
        _safeMint(msg.sender, 10);
    }

    function mint(uint256 amount) external payable {
        uint256 cost = price;
        uint256 num = amount > 0 ? amount : 1;
        bool free = ((totalSupply() + num < maxFreeAmount + 1) &&
            (_mintedFreeAmount[msg.sender] + num <= maxFreePerWallet));
        if (free) {
            cost = 0;
            _mintedFreeAmount[msg.sender] += num;
            require(num < maxFreePerTx + 1, "Max per TX reached.");
        } else {
            require(num < maxPerTx + 1, "Max per TX reached.");
        }

        require(mintEnabled, "Minting is not live yet.");
        require(msg.value >= num * cost, "Please send the exact amount.");
        require(totalSupply() + num < maxSupply + 1, "No more");

        _safeMint(msg.sender, num);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setMaxPerTx(uint256 _amount) external onlyOwner {
        maxPerTx = _amount;
    }

    function setMaxFreePerTx(uint256 _amount) external onlyOwner {
        maxFreePerTx = _amount;
    }

    function setMaxFreeAmount(uint256 _amount) external onlyOwner {
        maxFreeAmount = _amount;
    }

    function setMaxFreePerWallet(uint256 _amount) external onlyOwner {
        maxFreePerWallet = _amount;
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}