/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// File: contracts\libraries\SafeMath.sol

pragma solidity =0.6.6;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts\interfaces\IImx.sol

pragma solidity =0.6.6;
//IERC20?
interface IImx {
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
}

// File: contracts\interfaces\IClaimable.sol

pragma solidity =0.6.6;

interface IClaimable {
	function claim() external returns (uint amount);
	event Claim(address indexed account, uint amount);
}

// File: contracts\Distributor.sol

pragma solidity =0.6.6;




abstract contract Distributor is IClaimable {
	using SafeMath for uint;

	address public immutable imx;
	address public immutable claimable;

	struct Recipient {
		uint shares;
		uint lastShareIndex;
		uint credit;
	}
	mapping(address => Recipient) public recipients;
	
	uint public totalShares;
	uint public shareIndex;
	
	event UpdateShareIndex(uint shareIndex);
	event UpdateCredit(address indexed account, uint lastShareIndex, uint credit);
	event Claim(address indexed account, uint amount);
	event EditRecipient(address indexed account, uint shares, uint totalShares);

	constructor (
		address imx_,
		address claimable_
	) public {
		imx = imx_;
		claimable = claimable_;
	}
	
	function updateShareIndex() public virtual nonReentrant returns (uint _shareIndex) {
		if (totalShares == 0) return shareIndex;
		uint amount = IClaimable(claimable).claim();
		if (amount == 0) return shareIndex;
		_shareIndex = amount.mul(2**160).div(totalShares).add(shareIndex);
		shareIndex = _shareIndex;
		emit UpdateShareIndex(_shareIndex);
	}
	
	function updateCredit(address account) public returns (uint credit) {
		uint _shareIndex = updateShareIndex();
		if (_shareIndex == 0) return 0;
		Recipient storage recipient = recipients[account];
		credit = recipient.credit + _shareIndex.sub(recipient.lastShareIndex).mul(recipient.shares) / 2**160;
		recipient.lastShareIndex = _shareIndex;
		recipient.credit = credit;
		emit UpdateCredit(account, _shareIndex, credit);
	}

	function claimInternal(address account) internal virtual returns (uint amount) {
		amount = updateCredit(account);
		if (amount > 0) {
			recipients[account].credit = 0;
			IImx(imx).transfer(account, amount);
			emit Claim(account, amount);
		}
	}

	function claim() external virtual override returns (uint amount) {
		return claimInternal(msg.sender);
	}
	
	function editRecipientInternal(address account, uint shares) internal {
		updateCredit(account);
		Recipient storage recipient = recipients[account];
		uint prevShares = recipient.shares;
		uint _totalShares = shares > prevShares ? 
			totalShares.add(shares - prevShares) : 
			totalShares.sub(prevShares - shares);
		totalShares = _totalShares;
		recipient.shares = shares;
		emit EditRecipient(account, shares, _totalShares);
	}
	
	// Prevents a contract from calling itself, directly or indirectly.
	bool internal _notEntered = true;
	modifier nonReentrant() {
		require(_notEntered, "Distributor: REENTERED");
		_notEntered = false;
		_;
		_notEntered = true;
	}
}

// File: contracts\InitializedDistributor2.sol

pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;


contract InitializedDistributor is Distributor {
	
	struct Shareholder {
		address recipient;
		uint shares;
	}

	constructor (
		address imx_,
		address claimable_
	) public Distributor(imx_, claimable_) {	
		Shareholder[41] memory shareholders = [
			Shareholder({recipient: address(0xe49715C2f2D8004937d208b81736e0fdDef73D6c), shares: 762289}),
			Shareholder({recipient: address(0xD266d61ac22C2a2Ac2Dd832e79c14EA152c998D6), shares: 342602}),
			Shareholder({recipient: address(0x8E238b127f370fdaC5660331dB1DFC27f0D51583), shares: 685204}),
			Shareholder({recipient: address(0x00290ffc9e9D19bdA7b25c6e44d8ADF55DFBf2dD), shares: 411122}),
			Shareholder({recipient: address(0x877336CBC7210e9BFDaC31d9f0dDd5070be39184), shares: 239821}),
			Shareholder({recipient: address(0xA7F09CbcC67B50c8910BAa0c9A0d0C567921bd9B), shares: 274081}),
			Shareholder({recipient: address(0x04Ddb8ed83C1cbd593619F55579B11CE8B29e3A1), shares: 68520}),
			Shareholder({recipient: address(0x7cf4A93422b6ba2ca1e2eA2E3f572A847289927b), shares: 34260}),
			Shareholder({recipient: address(0xFF4df95b43A89724F23916A9C5aA41A6e9B1ce33), shares: 68520}),
			Shareholder({recipient: address(0x2C371D5C0B98370B1ca88231130fCc5ed2967666), shares: 68520}),
			Shareholder({recipient: address(0x66979BF23C37Ada615642db9148919136E18955E), shares: 34260}),
			Shareholder({recipient: address(0xa1d0B3B360595A82dbAAC1667535579bC568F8DD), shares: 13704}),
			Shareholder({recipient: address(0x21F60ffb54Da2251239cE01a9Ec07f5248451032), shares: 6852}),
			Shareholder({recipient: address(0x2D69BAB9738b05048be16DE3E5E0A945b8EeEf3a), shares: 20556}),
			Shareholder({recipient: address(0x788B0A2D87a16A3F745B0609D1b931773D10ccFF), shares: 17130}),
			Shareholder({recipient: address(0x50899582199c06d5264edDCD12879E5210783Ba8), shares: 17130}),
			Shareholder({recipient: address(0x5d28b7F00aA6fCaB66d95e2F5E3e7B5c850c53dc), shares: 17130}),
			Shareholder({recipient: address(0x11EfF19DC599ee676b6D65bae0A60479a87e889A), shares: 13704}),
			Shareholder({recipient: address(0x82Ba7508f7F1995AB1623258D66Cb4E2B2b8F467), shares: 27408}),
			Shareholder({recipient: address(0x9c2D043aAd476515da882DaA28e70C0dc7A63d67), shares: 10278}),
			Shareholder({recipient: address(0xd54921eDCdfb66c5181544A1FAe1Cbb81A025C59), shares: 6852}),
			Shareholder({recipient: address(0x41E3FE77DE1EcA115902eB058b1FB57395358d62), shares: 209843}),
			Shareholder({recipient: address(0xc14F2B9EDCbf083DB81070e851EdF4D7a1c9f966), shares: 34260}),
			Shareholder({recipient: address(0xCdA883De6a2E69Aed4dd1Ea2791e445a99E8E220), shares: 13704}),
			Shareholder({recipient: address(0xA16deCb38CF01dbdcFdaB0B9265AEfF1CFE9BD86), shares: 137040}),
			Shareholder({recipient: address(0xae08bc16F9AFB623EFE894147Dc36ed0eeB5CDB4), shares: 102780}),
			Shareholder({recipient: address(0xEF2314d95465507e62EadAbbfD9909413452BE1A), shares: 856505}),
			Shareholder({recipient: address(0x58Fde5bdB2C6Bd828Bc41c12a68189C7cd93dCE2), shares: 840915}),
			Shareholder({recipient: address(0x064Aa6fd8D407dA9a4E39D09AaA74a445FD17FC6), shares: 840915}),
			Shareholder({recipient: address(0x79E1f4495458f000Fa2b811910b191C80F082723), shares: 42825}),
			Shareholder({recipient: address(0xfc7e832837B2458B1455e3B670833b6a0c71f7Cb), shares: 42825}),
			Shareholder({recipient: address(0xe2a7C157a70E49BAdDdcB371b5967b25A26e44B9), shares: 42825}),
			Shareholder({recipient: address(0x799aCe5Ed6E05e86dd0AfCa7b1C2D75ECCDB8400), shares: 85650}),
			Shareholder({recipient: address(0x626Ef3b6a48b550c49869545F52E6c1853d293Bd), shares: 107063}),
			Shareholder({recipient: address(0xE443870ad9B4c632e4A63B3eD34cDC8546E67c8a), shares: 15110198}),
			Shareholder({recipient: address(0xe69ca0675F8775E787b04CD6A15a2426Aa6F71f3), shares: 109632}),
			Shareholder({recipient: address(0x2e371B91F66362D4120ed1120Ca9edBb3FA563be), shares: 8779176}),
			Shareholder({recipient: address(0xD4DdB60F506E3BE0Ee508a8773efacf7EBEF8515), shares: 428252}),
			Shareholder({recipient: address(0x88Cd805B81e99379c3473093cC6c1aCeb23940e7), shares: 1713010}),
			Shareholder({recipient: address(0x27714c8F5F2FAeb416c1129964C1780B97357862), shares: 1284757}),
			Shareholder({recipient: address(0x875Fa97D568B9844Ef7225aC0Eb66cfe845B4487), shares: 856505})
		];
		uint _totalShares = 0;
		for (uint i = 0; i < shareholders.length; i++) {
			recipients[shareholders[i].recipient].shares = shareholders[i].shares;
			_totalShares = _totalShares.add(shareholders[i].shares);
		}
		totalShares = _totalShares;
	}
	
	function setRecipient(address recipient_) public {
		require(recipients[msg.sender].shares > 0, "Distributor: NOT_A_RECIPIENT");
		require(recipients[recipient_].shares == 0, "Distributor: ALREADY_A_RECIPIENT");
		recipients[recipient_].shares = recipients[msg.sender].shares;
		recipients[recipient_].lastShareIndex = recipients[msg.sender].lastShareIndex;
		recipients[recipient_].credit = recipients[msg.sender].credit;
		recipients[msg.sender].shares = 0;
		recipients[msg.sender].lastShareIndex = 0;
		recipients[msg.sender].credit = 0;
	}

}