// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20PermitLight.sol";
import "./Equity.sol";
import "./IReserve.sol";
import "./IFrankencoin.sol";

contract Frankencoin is ERC20PermitLight, IFrankencoin {

   uint256 public constant MIN_FEE = 1000 * (10**18);
   uint256 public immutable MIN_APPLICATION_PERIOD; // for example 10 days

   IReserve override public immutable reserve;
   uint256 private minterReserveE6;

   mapping (address => uint256) public minters;
   mapping (address => address) public positions;

   event MinterApplied(address indexed minter, uint256 applicationPeriod, uint256 applicationFee, string message);
   event MinterDenied(address indexed minter, string message);

   /**
    * Initiates the Frankencoin with the provided minimum application period for new plugins
    * in seconds, for example 10 days, i.e. 3600*24*10 = 864000
    */
   constructor(uint256 _minApplicationPeriod) ERC20(18){
      MIN_APPLICATION_PERIOD = _minApplicationPeriod;
      reserve = new Equity(this);
   }

   function name() override external pure returns (string memory){
      return "Frankencoin V1";
   }

   function symbol() override external pure returns (string memory){
      return "ZCHF";
   }

   /**
    * @notice Minting is suggested either by (1) person applying for a new original position,
    * or (2) by the minting hub when cloning a position. The minting hub has the priviledge
    * to call with zero application fee and period.
    * @param _minter             address of the position want to add to the minters
    * @param _applicationPeriod  application period in seconds
    * @param _applicationFee     application fee in parts per million
    * @param _message            message string
    */
   function suggestMinter(address _minter, uint256 _applicationPeriod, 
      uint256 _applicationFee, string calldata _message) override external 
   {
      require(_applicationPeriod >= MIN_APPLICATION_PERIOD || totalSupply() == 0, "period too short");
      require(_applicationFee >= MIN_FEE || totalSupply() == 0, "fee too low");
      require(minters[_minter] == 0, "already registered");
      _transfer(msg.sender, address(reserve), _applicationFee);
      minters[_minter] = block.timestamp + _applicationPeriod;
      emit MinterApplied(_minter, _applicationPeriod, _applicationFee, _message);
   }

   function minterReserve() public view returns (uint256) {
      return minterReserveE6 / 1000000;
   }

   function registerPosition(address _position) override external {
      require(isMinter(msg.sender), "not minter");
      positions[_position] = msg.sender;
   }

   /**
    * @notice Get reserve balance (amount of ZCHF)
    * @return ZCHF in dec18 format
    */
   function equity() public view returns (uint256) {
      uint256 balance = balanceOf(address(reserve));
      uint256 minReserve = minterReserve();
      if (balance <= minReserve){
        return 0;
      } else {
        return balance - minReserve;
      }
    }

   function denyMinter(address _minter, address[] calldata _helpers, string calldata _message) override external {
      require(block.timestamp <= minters[_minter], "too late");
      require(reserve.isQualified(msg.sender, _helpers), "not qualified");
      delete minters[_minter];
      emit MinterDenied(_minter, _message);
   }

   /**
 * @notice Mint amount of ZCHF for address _target
 * @param _target       address that receives ZCHF if it's a minter
 * @param _amount       amount ZCHF before fees and pool contribution requested
 *                      number in dec18 format
 * @param _reservePPM   reserve requirement in parts per million
 * @param _feesPPM      fees in parts per million
 */
   function mint(address _target, uint256 _amount, uint32 _reservePPM, uint32 _feesPPM) override external minterOnly {
      uint256 _minterReserveE6 = _amount * _reservePPM;
      uint256 reserveMint = (_minterReserveE6 + 999_999) / 1000_000; // make sure rounded up
      uint256 fees = (_amount * _feesPPM + 999_999) / 1000_000; // make sure rounded up
      _mint(_target, _amount - reserveMint - fees);
      _mint(address(reserve), reserveMint + fees);
      minterReserveE6 += reserveMint * 1000_000;
   }

   /**
    * @notice Mint amount of ZCHF for address _target
    * @param _target   address that receives ZCHF if it's a minter
    * @param _amount   amount in dec18 format
    */
   function mint(address _target, uint256 _amount) override external minterOnly {
      _mint(_target, _amount);
   }

   function burn(uint256 _amount) external {
      _burn(msg.sender, _amount);
   }

   /**
    * Burn that amount without reclaiming the reserve.
    * The caller is only allowed to use this method for tokens also minted through the caller with the same _reservePPM amount.
    * For example, if someone minted 50 ZCHF earlier with a 20% reserve requirement (200000 ppm), they got 40 ZCHF and paid
    * 10 ZCHF into the reserve. Now they want to repay the debt by burning 50 ZCHF. When doing so using this method, the 10 ZCHF
    * that went into the reserve are not returned. Instead, they are donated to the reserve pool, making the pool share holders
    * richer. This can make sense in combination with 'notifyLoss', i.e. when it is the pool share holders that bear the risk
    * and depending on the outcome they make a profit or a loss.
    */
   function burn(uint256 amount, uint32 reservePPM) external override minterOnly {
      _burn(msg.sender, amount);
      minterReserveE6 -= amount * reservePPM;
   }

   function calculateAssignedReserve(uint256 mintedAmount, uint32 _reservePPM) public view returns (uint256) {
      uint256 theoreticalReserve = _reservePPM * mintedAmount / 1000000;
      uint256 currentReserve = balanceOf(address(reserve));
      if (currentReserve < minterReserve()){
         // not enough reserves, owner has to take a loss
         return theoreticalReserve * currentReserve / minterReserve();
      } else {
         return theoreticalReserve;
      }
   }

   /**
    * Burns the target amount taking the tokens to be burned from the payer and the payer's reserve.
    * The caller is only allowed to use this method for tokens also minted through the caller with the same _reservePPM amount.
    * Example: the calling contract has previously minted 100 ZCHF with a reserve ratio of 20% (i.e. 200000 ppm). To burn half
    * of that again, the minter calls burnFrom with a target amount of 50 ZCHF. Assuming that reserves are only 90% covered,
    * this call will deduct 41 ZCHF from the payer's balance and 9 from the reserve, while reducing the minter reserve by 10.
    */
   function burnFrom(address payer, uint256 targetTotalBurnAmount, uint32 _reservePPM) external override minterOnly returns (uint256) {
      uint256 assigned = calculateAssignedReserve(targetTotalBurnAmount, _reservePPM);
      _transfer(address(reserve), payer, assigned); 
      _burn(payer, targetTotalBurnAmount); // and burn everything
      minterReserveE6 -= targetTotalBurnAmount * _reservePPM; // reduce reserve requirements by original ratio
      return assigned;
   }

   /**
    * Burns the provided number of tokens plus whatever reserves are associated with that amount given the reserve requirement.
    * The caller is only allowed to use this method for tokens also minted through the caller with the same _reservePPM amount.
    * Example: the calling contract has previously minted 100 ZCHF with a reserve ratio of 20% (i.e. 200000 ppm). Now they have
    * 41 ZCHF that they do not need so they decide to repay that amount. Assuming the reserves are only 90% covered,
    * the call to burnWithReserve will burn the 41 plus 9 from the reserve, reducing the outstanding 'debt' of the caller by
    * 50 ZCHF in total. This total is returned by the method so the caller knows how much less they owe.
    */
   function burnWithReserve(uint256 _amountExcludingReserve /* 41 */, uint32 _reservePPM /* 20% */) 
      external override minterOnly returns (uint256) {
      uint256 currentReserve = balanceOf(address(reserve)); // 18, 10% below what we should have
      uint256 minterReserve_ = minterReserve(); // 20
      uint256 adjustedReservePPM = currentReserve < minterReserve_ ? _reservePPM * currentReserve / minterReserve_ : _reservePPM; // 18%
      uint256 freedAmount = 1000000 * _amountExcludingReserve / (1000000 - adjustedReservePPM); // 0.18 * 41 /0.82 = 50
      minterReserveE6 -= freedAmount * _reservePPM; // reduce reserve requirements by original ratio, here 10
      _transfer(address(reserve), msg.sender, freedAmount - _amountExcludingReserve); // collect 9 assigned reserve, maybe less than original reserve
      _burn(msg.sender, freedAmount); // 41
      return freedAmount;
   }

   function burn(address _owner, uint256 _amount) override external minterOnly {
      _burn(_owner, _amount);
   }

   modifier minterOnly() {
      require(isMinter(msg.sender) || isMinter(positions[msg.sender]), "not approved minter");
      _;
   }

   function notifyLoss(uint256 _amount) override external minterOnly {
      uint256 reserveLeft = balanceOf(address(reserve));
      if (reserveLeft >= _amount){
         _transfer(address(reserve), msg.sender, _amount);
      } else {
         _transfer(address(reserve), msg.sender, reserveLeft);
         _mint(msg.sender, _amount - reserveLeft);
      }
   }
   function isMinter(address _minter) override public view returns (bool){
      return minters[_minter] != 0 && block.timestamp >= minters[_minter];
   }

   function isPosition(address _position) override public view returns (address){
      return positions[_position];
   }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IReserve.sol";

interface IFrankencoin is IERC20 {

    function suggestMinter(address _minter, uint256 _applicationPeriod, 
      uint256 _applicationFee, string calldata _message) external;

    function registerPosition(address position) external;

    function denyMinter(address minter, address[] calldata helpers, string calldata message) external;

    function reserve() external view returns (IReserve);

    function isMinter(address minter) external view returns (bool);

    function isPosition(address position) external view returns (address);
    
    function mint(address target, uint256 amount) external;

    function mint(address target, uint256 amount, uint32 reservePPM, uint32 feePPM) external;

    function burn(uint256 amountIncludingReserve, uint32 reservePPM) external;

    function burnFrom(address payer, uint256 targetTotalBurnAmount, uint32 _reservePPM) external returns (uint256);

    function burnWithReserve(uint256 amountExcludingReserve, uint32 reservePPM) external returns (uint256);

    function burn(address target, uint256 amount) external;

    function notifyLoss(uint256 amount) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReserve {
   function isQualified(address sender, address[] calldata helpers) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./Frankencoin.sol";
import "./IERC677Receiver.sol";
import "./ERC20PermitLight.sol";
import "./MathUtil.sol";
import "./IReserve.sol";

/** 
 * @title Reserve pool for the Frankencoin
 */
contract Equity is ERC20PermitLight, MathUtil, IReserve {

    uint32 public constant VALUATION_FACTOR = 3;
    uint32 private constant QUORUM = 300;

    uint8 private constant BLOCK_TIME_RESOLUTION_BITS = 24;
    uint256 public constant MIN_HOLDING_DURATION = 90*7200 << BLOCK_TIME_RESOLUTION_BITS; // in blocks, about 90 days, set to 5 blocks for testing

    Frankencoin immutable public zchf;

    // should hopefully be grouped into one storage slot
    uint64 private totalVotesAnchorTime; // 40 Bit for the block number, 24 Bit sub-block time resolution
    uint192 private totalVotesAtAnchor;

    mapping (address => address) public delegates;
    mapping (address => uint64) private voteAnchor; // 40 Bit for the block number, 24 Bit sub-block time resolution

    event Delegation(address indexed from, address indexed to);
    event Trade(address who, int amount, uint totPrice, uint newprice); // amount pos or neg for mint or redemption

    constructor(Frankencoin zchf_) ERC20(18) {
        zchf = zchf_;
    }

    function name() override external pure returns (string memory) {
        return "Frankencoin Pool Share";
    }

    function symbol() override external pure returns (string memory) {
        return "FPS";
    }

    function price() public view returns (uint256){
        return VALUATION_FACTOR * zchf.equity() * ONE_DEC18 / totalSupply();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal {
        super._beforeTokenTransfer(from, to, amount);
        if (amount > 0){
            uint256 roundingLoss = adjustRecipientVoteAnchor(to, amount);
            adjustTotalVotes(from, amount, roundingLoss);
        }
    }

    function canRedeem() external view returns (bool){
        return canRedeem(msg.sender);
    }

    function canRedeem(address owner) public view returns (bool) {
        return anchorTime() - voteAnchor[owner] >= MIN_HOLDING_DURATION;
    }

     /**
     * @notice Decrease the total votes anchor when tokens lose their voting power due to being moved
     * @param from      sender
     * @param amount    amount to be sent
     */
    function adjustTotalVotes(address from, uint256 amount, uint256 roundingLoss) internal {
        uint256 lostVotes = from == address(0x0) ? 0 : (anchorTime() - voteAnchor[from]) * amount;
        totalVotesAtAnchor = uint192(totalVotes() - roundingLoss - lostVotes);
        totalVotesAnchorTime = anchorTime();
    }

    /**
     * @notice the vote anchor of the recipient is moved forward such that the number of calculated
     * votes does not change despite the higher balance.
     * @param to        receiver address
     * @param amount    amount to be received
     * @return the number of votes lost due to rounding errors
     */
    function adjustRecipientVoteAnchor(address to, uint256 amount) internal returns (uint256){
        if (to != address(0x0)) {
            uint256 recipientVotes = votes(to); // for example 21 if 7 shares were held for 3 blocks
            uint256 newbalance = balanceOf(to) + amount; // for example 11 if 4 shares are added
            voteAnchor[to] = uint64(anchorTime() - recipientVotes / newbalance); // new example anchor is only 21 / 11 = 1 block in the past
            return recipientVotes % newbalance; // we have lost 21 % 11 = 10 votes
        } else {
            // optimization for burn, vote anchor of null address does not matter
            return 0;
        }
    }

    function anchorTime() internal view returns (uint64){
        return uint64(block.number << BLOCK_TIME_RESOLUTION_BITS);
    }

    function votes(address holder) public view returns (uint256) {
        return balanceOf(holder) * (anchorTime() - voteAnchor[holder]);
    }

    function totalVotes() public view returns (uint256) {
        return totalVotesAtAnchor + totalSupply() * (anchorTime() - totalVotesAnchorTime);
    }

    function isQualified(address sender, address[] calldata helpers) external override view returns (bool) {
        uint256 _votes = votes(sender);
        for (uint i=0; i<helpers.length; i++){
            address current = helpers[i];
            require(current != sender);
            require(canVoteFor(sender, current));
            for (uint j=i+1; j<helpers.length; j++){
                require(current != helpers[j]); // ensure helper unique
            }
            _votes += votes(current);
        }
        return _votes * 10000 >= QUORUM * totalVotes();
    }

    function delegateVoteTo(address delegate) external {
        delegates[msg.sender] = delegate;
        emit Delegation(msg.sender, delegate);
    }

    function canVoteFor(address delegate, address owner) public view returns (bool) {
        if (owner == delegate){
            return true;
        } else if (owner == address(0x0)){
            return false;
        } else {
            return canVoteFor(delegate, delegates[owner]);
        }
    }

    function onTokenTransfer(address from, uint256 amount, bytes calldata) external returns (bool) {
        require(msg.sender == address(zchf), "caller must be zchf");
        if (totalSupply() == 0){
            require(amount >= ONE_DEC18, "initial deposit must >= 1");
            // initialize with 1000 shares for 1 ZCHF
            uint256 initialAmount = 1000 * ONE_DEC18;
            _mint(from, initialAmount);
            amount -= ONE_DEC18;
            emit Trade(msg.sender, int(initialAmount), ONE_DEC18, price());
        }
        uint256 shares = calculateSharesInternal(zchf.equity() - amount, amount);
        _mint(from, shares);
        require(totalSupply() < 2**90, "total supply exceeded"); // to guard against overflows with price and vote calculations
        emit Trade(msg.sender, int(shares), amount, price());
        return true;
    }

    /**
     * @notice Calculate shares received when depositing ZCHF
     * @dev this function is called after the transfer of ZCHF happens
     * @param investment ZCHF invested, in dec18 format
     * @return amount of shares received for the ZCHF invested
     */
    function calculateShares(uint256 investment) public view returns (uint256) {
        return calculateSharesInternal(zchf.equity(), investment);
    }

    function calculateSharesInternal(uint256 capitalBefore, uint256 investment) internal view returns (uint256) {
        uint256 totalShares = totalSupply();
        uint256 newTotalShares = _mulD18(totalShares, _cubicRoot(_divD18(capitalBefore + investment, capitalBefore)));
        return newTotalShares - totalShares;
    }

    function redeem(address target, uint256 shares) public returns (uint256) {
        require(canRedeem(msg.sender));
        uint256 proceeds = calculateProceeds(shares);
        _burn(msg.sender, shares);
        zchf.transfer(target, proceeds);
        emit Trade(msg.sender, -int(shares), proceeds, price());
        return proceeds;
    }

    /**
     * @notice Calculate ZCHF received when depositing shares
     * @dev this function is called before any transfer happens
     * @param shares number of shares we want to exchange for ZCHF,
     *               in dec18 format
     * @return amount of ZCHF received for the shares
     */
    function calculateProceeds(uint256 shares) public view returns (uint256) {
        uint256 totalShares = totalSupply();
        uint256 capital = zchf.equity();
        require(shares + ONE_DEC18 < totalShares, "too many shares"); // make sure there is always at least one share
        uint256 newTotalShares = totalShares - shares;
        uint256 newCapital = _mulD18(capital, _power3(_divD18(newTotalShares, totalShares)));
        return capital - newCapital;
    }

}

// SPDX-License-Identifier: MIT
// Copied from https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol
// and modified it.

pragma solidity ^0.8.0;

import "./ERC20.sol";

abstract contract ERC20PermitLight is ERC20 {
   
   /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public nonces;

  /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        unchecked { // unchecked to save a little gas with the nonce increment...
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                                bytes32(0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");
            _approve(recoveredAddress, spender, value);
        }
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    //keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
                    bytes32(0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218),
                    block.chainid,
                    address(this)
                )
            );
    }

}

/**
* SPDX-License-Identifier: MIT
*
* Copyright (c) 2016-2019 zOS Global Limited
*
*/
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */

interface IERC20 {

    // Optional functions
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferAndCall(address recipient, uint256 amount, bytes calldata data) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/** 
 * @title Functions for share valuation
 */
contract MathUtil {

    uint256 internal constant ONE_DEC18 = 10**18;
    uint256 internal constant THRESH_DEC18 =  10000000000000000;//0.01
    /**
     * @notice Cubic root with Halley approximation
     *         Number 1e18 decimal
     * @param _v     number for which we calculate x**(1/3)
     * @return returns _v**(1/3)
     */
    function _cubicRoot(uint256 _v) internal pure returns (uint256) {
        uint256 x = ONE_DEC18;
        uint256 xOld;
        bool cond;
        do {
            xOld = x;
            uint256 powX3 = _mulD18(_mulD18(x, x), x);
            x = _mulD18(x, _divD18( (powX3 + 2 * _v) , (2 * powX3 + _v)));
            cond = xOld > x ? xOld - x > THRESH_DEC18 : x - xOld > THRESH_DEC18;
        } while ( cond );
        return x;
    }

    function _mulD18(uint256 _a, uint256 _b) internal pure returns(uint256) {
        return _a * _b / ONE_DEC18;
    }

    function _divD18(uint256 _a, uint256 _b) internal pure returns(uint256) {
        return (_a * ONE_DEC18) / _b ;
    }

    function _power3(uint256 _x) internal pure returns(uint256) {
        return _mulD18(_mulD18(_x, _x), _x);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC677Receiver {
    
    function onTokenTransfer(address from, uint256 amount, bytes calldata data) external returns (bool);

}

// SPDX-License-Identifier: MIT
// Copied and adjusted from OpenZeppelin
// Adjustments:
// - modifications to support ERC-677
// - removed require messages to save space
// - removed unnecessary require statements
// - removed GSN Context
// - upgraded to 0.8 to drop SafeMath
// - let name() and symbol() be implemented by subclass
// - infinite allowance support, with 2^255 and above considered infinite

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC677Receiver.sol";

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */

abstract contract ERC20 is IERC20 {

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    uint8 public immutable override decimals;

    constructor(uint8 _decimals) {
        decimals = _decimals;
    }

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance < (1 << 255)){
            // Only decrease the allowance if it was not set to 'infinite'
            // Documented in /doc/infiniteallowance.md
            require(currentAllowance >= amount, "approval not enough");
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(recipient != address(0));
        
        _beforeTokenTransfer(sender, recipient, amount);
        require(_balances[sender]>=amount, "balance not enough");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    // ERC-677 functionality, can be useful for swapping and wrapping tokens
    function transferAndCall(address recipient, uint256 amount, bytes calldata data) external override returns (bool) {
        bool success = transfer(recipient, amount);
        if (success){
            success = IERC677Receiver(recipient).onTokenTransfer(msg.sender, amount, data);
        }
        return success;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address recipient, uint256 amount) internal virtual {
        require(recipient != address(0));

        _beforeTokenTransfer(address(0), recipient, amount);

        _totalSupply += amount;
        _balances[recipient] += amount;
        emit Transfer(address(0), recipient, amount);
    }

     /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        _beforeTokenTransfer(account, address(0), amount);

        _totalSupply -= amount;
        _balances[account] -= amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) virtual internal {
    }
}