/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: Unlicense
// Sources flattened with hardhat v2.8.3 https://hardhat.org
pragma solidity ^0.8.4;

// File @openzeppelin/contracts/utils/[email protected]
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// File @openzeppelin/contracts/access/[email protected]
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


// File @openzeppelin/contracts/token/ERC20/[email protected]
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/Secondaries.sol
// Secondaries Contract

contract Secondaries is Ownable {
    struct Dist {
        uint256 share;
        uint256 loc;
        string name;
    }

    mapping(address => Dist) private _distMap;
    address[] private _distList;
    uint256 private _shareTotal = 0;

    struct Token {
        bool state;
        uint256 loc;
        string name;
    }

    mapping(address => Token) private _tokenMap;
    address[] private _tokenList;

    event Distribution(uint256 amount, string token);
    event DistributionListChange(address indexed target, bool isIncluded);
    event TokenListChange(address indexed target, bool isIncluded);

    constructor(
        address[] memory addresses,
        string[] memory names,
        uint256[] memory royalty,
        address[] memory erc20Addresses,
        string[] memory erc20Names
    ) {
        for (uint256 i = 0; i < addresses.length; i++) {
            addDist(addresses[i], names[i], royalty[i]);
        }

        for (uint256 i = 0; i < erc20Addresses.length; i++) {
            addToken(erc20Addresses[i], erc20Names[i]);
        }
    }

    receive() external payable {}

    fallback() external payable {}

    function getShareTotal() public view returns (uint256) {
        return _shareTotal;
    }

    function getShare(address account) public view returns (uint256) {
        return _distMap[account].share;
    }

    function getName(address account) public view returns (string memory) {
        return _distMap[account].name;
    }

    function allDist() public view returns (address[] memory) {
        return _distList;
    }

    function isDist(address account) public view returns (bool) {
        return (getShare(account) > 0);
    }

    function allTokens() public view returns (address[] memory) {
        return _tokenList;
    }

    function getTokenName(address _tokenAddress)
        public
        view
        returns (string memory)
    {
        return _tokenMap[_tokenAddress].name;
    }

    function isToken(address _tokenAddress) public view returns (bool) {
        return _tokenMap[_tokenAddress].state;
    }

    function shareTotal() private {
        uint256 sum;
        for (uint256 i = 0; i < _distList.length; i++) {
            sum += _distMap[_distList[i]].share;
        }
        _shareTotal = sum;
    }

    function addDist(
        address _address,
        string memory _Name,
        uint256 _share
    ) public onlyOwner {
        require(_address != address(0), "Invalid address");
        require(_share > 0, "Share must be greater than zero");
        Dist storage d = _distMap[_address];
        require(d.share == 0, "Address already in distribution list");

        d.share = _share;
        d.loc = _distList.length;
        d.name = _Name;

        _distList.push(_address);
        emit DistributionListChange(_address, true);
        shareTotal();
    }

    function removeDist(address _address) public onlyOwner {
        Dist storage d = _distMap[_address];
        require(d.share > 0, "Address not in distribution list");
        d.share = 0;

        address _last = _distList[_distList.length - 1];
        _distMap[_last].loc = d.loc;
        _distList[d.loc] = _last;
        _distList.pop();

        emit DistributionListChange(_address, false);
        shareTotal();
    }

    function editDistName(address _address, string memory _Name)
        external
        onlyOwner
    {
        Dist storage d = _distMap[_address];
        require(d.share > 0, "Address not in distribution list");
        d.name = _Name;
    }

    function editDistShare(address _address, uint256 _share)
        external
        onlyOwner
    {
        require(_share > 0, "To set share to zero, use removeDist()");
        Dist storage d = _distMap[_address];
        require(d.share > 0, "Address not in distribution list");

        d.share = _share;
        shareTotal();
    }

    function editDistAddress(string memory _Name, address _newAddress)
	external
	onlyOwner
    {
	address _oldAddress;
	Dist memory d;

	for (uint256 i = 0; i < _distList.length; i++) {
	_oldAddress = _distList[i];
	d = _distMap[_oldAddress];

	    if (keccak256(bytes(d.name)) == keccak256(bytes(_Name))) {
		removeDist(_oldAddress);
		addDist(_newAddress, _Name, d.share);
	    }
	}
    }

    function addToken(address _address, string memory _Name) public onlyOwner {
        require(_address != address(0), "Invalid address");
        Token storage t = _tokenMap[_address];
        require(!t.state, "Address already in token list");

        t.state = true;
        t.loc = _tokenList.length;
        t.name = _Name;

        _tokenList.push(_address);
        emit TokenListChange(_address, true);
    }

    function removeToken(address _address) external onlyOwner {
        Token storage t = _tokenMap[_address];
        require(t.state, "Address not in token list");
        t.state = false;

        address _last = _tokenList[_tokenList.length - 1];
        _tokenMap[_last].loc = t.loc;
        _tokenList[t.loc] = _last;
        _tokenList.pop();

        emit TokenListChange(_address, false);
    }

    function distribute() external {
        if (_distList.length > 0) {
            // distribute ETH
            uint256 _balance = address(this).balance;
            uint256 _unit;
            address _address;

            if (_balance > 0) {
                _unit = _balance / _shareTotal;

                for (uint256 i = 0; i < _distList.length; i++) {
                    _address = _distList[i];
                    payable(_address).transfer(
                        _distMap[_address].share * _unit
                    );
                }
                emit Distribution(_balance, "ETH");
            }

            // distribute other tokens
            if (_tokenList.length > 0) {
                IERC20 _token;
                for (uint256 i = 0; i < _tokenList.length; i++) {
                    _token = IERC20(_tokenList[i]);
                    _balance = _token.balanceOf(address(this));

                    if (_balance > 0) {
                        _unit = _balance / _shareTotal;

                        for (uint256 j = 0; j < _distList.length; j++) {
                            _address = _distList[j];
                            _token.transfer(
                                _address,
                                _distMap[_address].share * _unit
                            );
                        }
                        emit Distribution(
                            _balance,
                            _tokenMap[_tokenList[i]].name
                        );
                    }
                }
            }
        }
    }
}