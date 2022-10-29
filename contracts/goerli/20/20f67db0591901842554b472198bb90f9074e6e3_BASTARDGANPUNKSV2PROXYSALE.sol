/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

pragma solidity ^0.8.0;

// PROXY SALE CONTRACT FOR ORBITS

// @berkozdemir https://berkozdemir.com

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface ORBITSNFT {

    function mintOrbit() external payable;
    function totalSupply() external view returns (uint256);
    function safeTransferFrom(
            address from,
            address to,
            uint256 tokenId,
            bytes calldata data
        ) external;

}


interface IGLIX {
    function burn(address from, uint256 amount) external returns (bool);
}


// THIS IS WHERE THE MAGIC HAPPENS

contract BASTARDGANPUNKSV2PROXYSALE is Ownable, IERC721Receiver {

    address payable public treasuryAddress;

    bool public saleRunning = false;
    uint orbitsprice = 0.0777 ether;
    // uint price = 0.015 ether;
    uint price = 0.0015 ether;

    uint glixprice = 500 ether;

    // address public ORBITSADDRESS =
    //     0x31385d3520bCED94f77AaE104b406994D8F2168C;
    address public ORBITSADDRESS =
        0x829893153D72C7f57C20C2DF146Db846aAc6216e;
    address private GLIXTOKEN_ADDRESS = 0x4e09d18baa1dA0b396d1A48803956FAc01c28E88; // mainnet


    constructor() {
    }

    receive() external payable {}

    function flipSale() public onlyOwner {
        saleRunning = !saleRunning;
    }
   

    function buyWithEther(uint256 _amount)
        public
        payable
    {
        require(saleRunning, "Minting not open");
        
        require(
            msg.value >= price * _amount,
            "YOU HAVEN'T PAID ENOUGH LOL"
        );
  
        uint256 originalPrice =
            orbitsprice * _amount;

        uint256 total = ORBITSNFT(ORBITSADDRESS).totalSupply();
        for (uint256 i = 0; i < _amount; i++) {
            ORBITSNFT(ORBITSADDRESS).mintOrbit{value: originalPrice}();

            ORBITSNFT(ORBITSADDRESS).safeTransferFrom(
                address(this),
                msg.sender,
                total + i,
                ""
            );
        }
    }

    function buyWithGlix(uint256 _amount)
        public
        payable
    {
        require(saleRunning, "Minting not open");
        

       require(
            IGLIX(GLIXTOKEN_ADDRESS).burn(
                msg.sender,
                glixprice * _amount
            )
        );
        uint256 originalPrice =
            orbitsprice * _amount;
        uint256 total = ORBITSNFT(ORBITSADDRESS).totalSupply();
        for (uint256 i = 0; i < _amount; i++) {
            ORBITSNFT(ORBITSADDRESS).mintOrbit{value: originalPrice}();

            ORBITSNFT(ORBITSADDRESS).safeTransferFrom(
                address(this),
                msg.sender,
                total + i,
                ""
            );
        }
    }

    function addFundsToContract() public payable onlyOwner {
        payable(address(this)).transfer(msg.value);
    }

    function returnFunds() public onlyOwner {
        treasuryAddress.transfer(address(this).balance);
    }

    function setTreasuryAddress(address payable _address) public onlyOwner {
        treasuryAddress = _address;
    }
    function changeEtherPrice(uint _price) public onlyOwner {
        price = _price;
    }
    function changeGlixPrice(uint _price) public onlyOwner {
        glixprice = _price;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}