//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IEivissaProject.sol";
import "./Bidder.sol";
import "./IMRC.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Auction {
	uint256[3] public maxSupplies;
	uint256[3] public minPrices;
	Bidder[][3] public bidders;
	IMRC mrc;
	IERC20 usd;
	string public name;
	bool public paused = true;
	bool public whitelistEnabled = true;
	mapping(address => bool) public isAdmin;
	mapping(address => bool) public whitelist;
	IEivissaProject eivissa;

	modifier isNotPaused() {
		require(paused == false, "Paused");
		_;
	}

	modifier onlyAdmin {
		require(isAdmin[msg.sender] == true, "Only Admins");
		_;
	}

	modifier whitelisted {
		if (whitelistEnabled == true)
			require(whitelist[msg.sender] == true, "Whitelist");
		_;
	}

	modifier onlyHolder {
		require(mrc.balanceOf(msg.sender) > 0 || isAdmin[msg.sender] == true, "Only Holders");
		_;
	}

	modifier onlyEivissa {
		require(msg.sender == address(eivissa), "Only Eivissa");
		_;
	}

	constructor(IEivissaProject eivissa_,
				uint256[3] memory maxSupplies_,
				uint256[3] memory minPrices_,
				string memory name_,
				IMRC mrc_,
				IERC20 usd_,
				address newAdmin) {
		eivissa = eivissa_;
		maxSupplies = maxSupplies_;
		minPrices = minPrices_;
		mrc = mrc_;
		usd = usd_;
		name = name_;
		isAdmin[address(eivissa)] = true;
		isAdmin[newAdmin] = true;
	}

	//PUBLIC

	function bid(uint256 id, uint256 price) public isNotPaused onlyHolder whitelisted {
		require(id < 3, "Invalid index");
		if (bidders[id].length == maxSupplies[id])
			require(price > minPrices[id], "Price");
		else
			require(price >= minPrices[id], "Price");

		usd.transferFrom(msg.sender, address(this), price);
		addBidder(msg.sender, price, id);
	}

	function getRank(uint256 id, address wallet) public view returns(uint256) {
		for (uint256 i = 0; i < bidders[id].length; ++i)
			if (bidders[id][i].wallet == wallet)
				return i;
		return bidders[id].length;
	}

	function playPause() public onlyAdmin {
		paused = !paused;
	}

	function finish() public onlyEivissa {
		for (uint256 id = 0; id < 3; ++id)
			for (uint256 i = 0; i < bidders[id].length; ++i)
				eivissa.mint(bidders[id][i].wallet, id, bidders[id][i].amount);
		usd.transfer(address(eivissa), usd.balanceOf(address(this)));
		selfdestruct(payable(address(eivissa)));
	}

	function addAdmin(address[] memory newOnes) public onlyAdmin {
		for (uint256 i = 0; i < newOnes.length; ++i)
			isAdmin[newOnes[i]] = true;
	}

	function removeAdmin(address[] memory newOnes) public onlyAdmin {
		for (uint256 i = 0; i < newOnes.length; ++i) {
			if (newOnes[i] != msg.sender)
				isAdmin[newOnes[i]] = false;
		}
	}

	function addToWhitelist(address[] memory newOnes) public onlyAdmin {
		for (uint256 i = 0; i < newOnes.length; ++i)
			whitelist[newOnes[i]] = true;
	}

	function removeFromWhitelist(address[] memory newOnes) public onlyAdmin {
		for (uint256 i = 0; i < newOnes.length; ++i)
			whitelist[newOnes[i]] = false;
	}

	function switchWhitelist() public onlyAdmin {
		whitelistEnabled = !whitelistEnabled;
	}

	//INTERNAL

	function addBidder(address newOne, uint256 amount, uint256 id) private {
		if (bidders[id].length < maxSupplies[id]) {
			bidders[id].push(Bidder(newOne, amount));
		} else {
			Bidder memory tmp = Bidder(newOne, amount);
			for (uint256 i = 0; i < bidders[id].length; ++i) {
				if (tmp.amount >= bidders[id][i].amount) {
					Bidder memory aux = bidders[id][i];
					bidders[id][i] = tmp;
					tmp = aux;
				}
			}
			usd.transfer(tmp.wallet, tmp.amount);
		}
		if (bidders[id].length == maxSupplies[id])
			minPrices[id] = bidders[id][bidders.length - 1].amount;
	}

	receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IEivissaProject {
	function mint(address to, uint256 id, uint256 price) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct Bidder {
	address wallet;
	uint256 amount;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IMRC {
	function balanceOf(address owner) external view returns (uint256 balance);
	function walletOfOwner(address account) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}