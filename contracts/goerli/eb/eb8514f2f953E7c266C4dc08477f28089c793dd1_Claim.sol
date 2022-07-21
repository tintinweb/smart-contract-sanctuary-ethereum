// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../libraries/SafeERC20.sol";
import "../types/Ownable.sol";
import "../interfaces/IClaim.sol";
import "../interfaces/IERC20Metadata.sol";

/**
 *  This contract allows seed investors, advisers and the team to claim tokens.
 *  Current functionality of the contract merely allows to set terms of future vesting.
 *  Thus, it has a functionality not for redeeming but for buying and setting shares of seed investors and genesis team.
 */
contract Claim is Ownable {
    /* ========== DEPENDENCIES ========== */

    using SafeERC20 for IERC20;

    /* ========== STRUCTS ========== */

    struct Term {
        uint256 percent; // 4 decimals ( 5000 = 0.5% )
        uint256 max; // maximum nominal GRAD amount can claim (9 decimals)
        Claimers claimer; // type of claimer (0 - team, 1 - investor, 2 - adviser)
    }

    enum Claimers {
        Team,
        Investors,
        Advisers
    }

    /* ========== EVENTS ============= */

    // set terms event
    event SetTerm(
        address indexed _address,
        uint256 _percent,
        uint256 _max,
        Claimers indexed _claimer
    );

    // change wallet event
    event WalletChange(
        address indexed _oldAddress,
        address indexed _newAddress
    );

    /* ========== STATE VARIABLES ========== */

    // payment token
    IERC20 public paymentToken;

    // previous deployment of contract (to migrate terms). It's the first version
    IClaim internal immutable previous = IClaim(address(0));

    // tracks address info
    mapping(address => Term) public terms;

    // facilitates address change
    mapping(address => address) public walletChange;

    // maximum portion of supply can allocate (10% team, 5% investors, 3% advisers) (4 decimals)
    uint256[3] public maximumAllocatedPercents = [10 * 1e4, 5 * 1e4, 3 * 1e4];

    // maximum amount of GRAD can allocate (330mm team, 70mm investors, 50mm advisers) (9 decimals)
    uint256[3] public maximumAllocatedTokens = [
        330 * 1e6 * 1e9,
        70 * 1e6 * 1e9,
        50 * 1e6 * 1e9
    ];

    // current allocated percents
    uint256[3] public totalAllocatedPercents = [0, 0, 0];

    // current allocated GRADs
    uint256[3] public totalAllocatedTokens = [0, 0, 0];

    // sale status
    bool public saleOpened;

    // sale whitelist (amount for each address)
    mapping(address => uint256) public saleInvestorWhitelist;

    uint256 public gradPrice; // 4 decimals ($1 = 10000)

    constructor(uint256 _gradPrice, address _token) {
        gradPrice = _gradPrice;
        paymentToken = IERC20(_token);
    }

    /* ========== CLAIMERS FUNCTIONS ========== */

    /**
     * @notice allows address to push terms to new address
     * @dev
     * @param _address address to send allocation
     * @param _amount amount of GRAD to buy
     */
    function buyInvestorsAllocation(address _address, uint256 _amount)
        external
    {
        require(saleOpened, "Sale is closed");
        require(
            saleInvestorWhitelist[msg.sender] != 0,
            "Address is not whitelisted"
        );
        require(
            saleInvestorWhitelist[msg.sender] >= _amount,
            "Cannot buy more than allowed"
        );

        saleInvestorWhitelist[msg.sender] -= _amount;

        uint256 claimer = uint256(Claimers.Investors);

        uint256 percent_ = getShare(
            _amount,
            maximumAllocatedTokens[claimer],
            maximumAllocatedPercents[claimer]
        );

        IERC20Metadata paymentTokenMetadata = IERC20Metadata(
            address(paymentToken)
        );
        paymentToken.safeTransferFrom(
            msg.sender,
            address(this),
            (_amount * gradPrice * 10**paymentTokenMetadata.decimals()) / 1e13 // 18 (dai) - 9 (grad) - 4 (gradPrice) decimals
        );

        _setTerm(_address, percent_, _amount, Claimers.Investors);
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    /**
     * @notice allows address to push terms to new address
     * @param _newAddress address
     */
    function pushWalletChange(address _newAddress) external {
        require(terms[msg.sender].percent != 0, "No wallet to change");
        walletChange[msg.sender] = _newAddress;
    }

    /**
     * @notice allows new address to pull terms
     * @param _oldAddress address
     */
    function pullWalletChange(address _oldAddress) external {
        require(
            walletChange[_oldAddress] == msg.sender,
            "Old wallet did not push"
        );
        require(terms[msg.sender].percent == 0, "Wallet already exists");

        walletChange[_oldAddress] = address(0);
        terms[msg.sender] = terms[_oldAddress];
        delete terms[_oldAddress];
        emit WalletChange(_oldAddress, msg.sender);
    }

    /* ========== OWNER FUNCTIONS ========== */

    /**
     * @notice toggle sale status
     */
    function toggleSaleStatus() external onlyOwner returns (bool) {
        saleOpened = !saleOpened;
        return !saleOpened;
    }

    /**
     * @notice change GRAD price ($1 = 10000)
     * @param _newPrice new price for GRAD (4 decimals)
     */
    function changeGradPrice(uint256 _newPrice) external onlyOwner {
        gradPrice = _newPrice;
    }

    /**
     * @notice change payment token
     * @param _newPaymentToken new token address
     */
    function changePaymentToken(address _newPaymentToken) external onlyOwner {
        paymentToken = IERC20(_newPaymentToken);
    }

    /**
     * @notice add, remove or change members of whitelist
     * @param _address address
     * @param _amount amount of GRAD allowed to buy
     */
    function setAddressToInvestorWhitelist(address _address, uint256 _amount)
        external
        onlyOwner
    {
        saleInvestorWhitelist[_address] = _amount;
    }

    /**
     * @notice withdraw dai
     * @param _to address to withdraw
     * @param _asset erc20 token to withdraw
     * @param _amount amount to withdraw
     */
    function withdraw(
        address _to,
        address _asset,
        uint256 _amount
    ) external onlyOwner { 
        IERC20 token;
        if (_asset == address(0)) {
            token = paymentToken;
        } else {
            token = IERC20(_asset);
        }
        token.safeTransfer(_to, _amount);
    }

    function setTerm(
        address _address,
        uint256 _percent,
        uint256 _max,
        Claimers _claimer
    ) external onlyOwner {
        _setTerm(_address, _percent, _max, _claimer);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     *  @notice set a term for a claimer
     *  @dev can be changed by the owner
     *  @param _address address
     *  @param _percent uint256
     *  @param _max uint256
     *  @param _claimer type of claimer (team, investor, adviser)
     */
    function _setTerm(
        address _address,
        uint256 _percent,
        uint256 _max,
        Claimers _claimer
    ) internal {

        require(
            terms[_address].max == 0 || terms[_address].claimer == _claimer,
            "Cannot change type of claimer"    
        );

        uint256 claimer = uint256(_claimer);

        uint256 newTotalAllocatedPercents = totalAllocatedPercents[claimer] -
            terms[_address].percent +
            _percent;

        uint256 newTotalAllocatedTokens = totalAllocatedTokens[claimer] -
            terms[_address].max +
            _max;

        require(
            newTotalAllocatedPercents <= maximumAllocatedPercents[claimer],
            "Cannot allocate more percents"
        );

        require(
            newTotalAllocatedTokens <= maximumAllocatedTokens[claimer],
            "Cannot allocate more tokens"
        );

        totalAllocatedPercents[claimer] = newTotalAllocatedPercents;

        totalAllocatedTokens[claimer] = newTotalAllocatedTokens;

        terms[_address] = Term({
            percent: _percent,
            max: _max,
            claimer: _claimer
        });
        emit SetTerm(_address, _percent, _max, _claimer);
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    /**
     * @notice value2_ is such share of _amount2 as _value1 is of _amount1
     * @param _value1 uint256
     * @param _amount1 uint256
     * @param _amount2 uint256
     * @param value2_ uint256
     */
    function getShare(
        uint256 _value1,
        uint256 _amount1,
        uint256 _amount2
    ) public pure returns (uint256 value2_) {
        value2_ = (_value1 * _amount2) / _amount1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

import "../interfaces/IOwnable.sol";

abstract contract Ownable is IOwnable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceManagement() public virtual override onlyOwner {
        emit OwnershipPulled(_owner, address(0));
        _owner = address(0);
        _newOwner = address(0);
    }

    function pushManagement(address newOwner_) public virtual override onlyOwner {
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
        _newOwner = address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../libraries/SafeERC20.sol";
import "../types/Ownable.sol";

interface IClaim {
    struct Term {
        uint256 percent; // 4 decimals ( 5000 = 0.5% )
        uint256 gClaimed; // static number
        uint256 max; // maximum nominal GRAD amount can claim
        uint256 claimer;
    }

    struct Claimers {
        uint256 team;
        uint256 investors;
        uint256 advisers;
    }

    function terms(address _address) external view returns (Term memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IOwnable {
    function owner() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}