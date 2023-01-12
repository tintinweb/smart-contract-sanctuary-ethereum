/**
 *Submitted for verification at Etherscan.io on 2023-01-12
*/

// File: contracts/INFT.sol



pragma solidity ^0.8.0;



interface INFT {

	function mint(address _to) external;

	function mintBatch(address _to, uint _amount) external;

}
// File: openzeppelin-solidity/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/NftSale.sol



pragma solidity ^0.8.0;





contract NftSale is Ownable {



	uint public  MAX_UNITS_PER_TRANSACTION = 5;

	uint public constant MAX_NFT_TO_SELL = 10000;

	

	uint public  SALE_PRICE = 0.01 ether;

	uint public constant START_TIME = 1673017006;

	

	INFT public nft;

	uint public tokensSold;



	constructor(address _nftAddress) {

		nft = INFT(_nftAddress);

	}

	



    /*

     * @dev function to set SALE_PRICE

     * @param _SALE_PRICE Sale Price

     */

	function changeSalePrice(uint _SALE_PRICE) public onlyOwner {

		SALE_PRICE = _SALE_PRICE;

	}



	/*

	 * @dev function to buy tokens. 

	 * @param _amount how much tokens can be bought.

	 */

	function buyBatch(uint _amount) external payable {

		require(tokensSold + _amount <= MAX_NFT_TO_SELL, "exceed sell limit");

		require(_amount > 0, "empty input");

		require(_amount <= MAX_UNITS_PER_TRANSACTION, "exceed MAX_UNITS_PER_TRANSACTION");



		uint totalPrice = SALE_PRICE * _amount;

		require(msg.value >= totalPrice, "too low value");

		if(msg.value > totalPrice) {

			//send the rest back

			(bool sent, ) = payable(msg.sender).call{value: msg.value - totalPrice}("");

        	require(sent, "Failed to send Ether");

		}

		

		tokensSold += _amount;

		nft.mintBatch(msg.sender, _amount);

	}



	function cashOut(address _to) public onlyOwner {

        // Call returns a boolean value indicating success or failure.

        // This is the current recommended method to use.

        (bool sent, ) = _to.call{value: address(this).balance}("");

        require(sent, "Failed to send Ether");

    }



    /*

     * @dev function to set MAX_UNITS_PER_TRANSACTION

     * @param _MAX_UNITS_PER_TRANSACTION Max unit per transaction

     */

	function changeMaxUnitsPerTransaction(uint _MAX_UNITS_PER_TRANSACTION) public onlyOwner {

		MAX_UNITS_PER_TRANSACTION = _MAX_UNITS_PER_TRANSACTION;

	}  

}