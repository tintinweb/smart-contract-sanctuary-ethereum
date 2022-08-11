// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./struct/IDO.sol";
import "./modifier/PoolModifier.sol";

contract Pool is PoolModifier {
    uint256 private _totalIdo;
    mapping(uint256 => IDO) private _ido;
    mapping(uint256 => uint256) private _rateTokenToIdo;

    constructor() {}

    function addIDO(
        address tokenCurrency,
        address idoCurrency,
        uint256 tokenSupply,
        uint256 idoSupply,
        string memory idoMetadata,
        uint256 endTime
    )
        public
        expired(endTime)
        balanceCheck(idoCurrency, idoSupply)
        greaterThanZero(tokenSupply)
        greaterThanZero(idoSupply)
    {
        IERC20(idoCurrency).transferFrom(msg.sender, address(this), idoSupply);

        IDO memory newIDO = IDO(
            msg.sender,
            tokenCurrency,
            idoCurrency,
            tokenSupply,
            idoSupply,
            idoMetadata,
            endTime
        );

        uint256 idoID = ++_totalIdo;
        _rateTokenToIdo[idoID] = idoSupply / tokenSupply;
        _ido[idoID] = newIDO;
    }

    function buyIDO(uint256 _id, uint256 _amountToken)
        public
        expired(_ido[_id].endTime)
        balanceCheck(_ido[_id].tokenCurrency, _amountToken)
        greaterThanZero(_amountToken)
    {
        IERC20(_ido[_id].tokenCurrency).transferFrom(
            msg.sender,
            address(this),
            _amountToken
        );
        IERC20(_ido[_id].idoCurrency).transfer(
            msg.sender,
            _amountToken * _rateTokenToIdo[_id]
        );
    }

    function claimLeftIdo(uint256 _id) public onlyOwner(_ido[_id].owner) {
        require(isIDOEnded(_id), "IDO is not ended");
        IERC20 idoERC20 = IERC20(_ido[_id].idoCurrency);
        idoERC20.transfer(_ido[_id].owner, idoERC20.balanceOf(address(this)));
    }

    function isIDOEnded(uint256 _id) public view returns (bool) {
        return block.timestamp >= _ido[_id].endTime;
    }

    function getIDO(uint256 _id) public view returns (IDO memory) {
        return _ido[_id];
    }

    function getTotalIDO() public view returns (uint256) {
        return _totalIdo;
    }
}
// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// 1759374231

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct IDO {
    address owner;
    address tokenCurrency;
    address idoCurrency;
    uint256 tokenSupply;
    uint256 idoSupply;
    string idoMetadata;
    uint256 endTime;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract PoolModifier {
    modifier expired(uint256 endTime) {
        require(block.timestamp < endTime, "IDO is expired");
        _;
    }

    modifier balanceCheck(address _token, uint256 _value) {
        require(IERC20(_token).balanceOf(msg.sender) >= _value);
        _;
    }

    modifier greaterThanZero(uint256 _value) {
        require(_value > 0);
        _;
    }

    modifier onlyOwner(address _owner) {
        require(msg.sender == _owner);
        _;
    }
}