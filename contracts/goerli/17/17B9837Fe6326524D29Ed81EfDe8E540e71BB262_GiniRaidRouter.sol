// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 >=0.8.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private creator;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

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
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract GiniRaidRouter is Ownable {
    receive() external payable {}

    // modifiers
    modifier onlyCreatorOrOwner(uint256 raidID) {
        require(
            msg.sender == owner() || msg.sender == raids[raidID].Creator,
            "You are not the creator or owner"
        );
        _;
    }

    //enums
    enum RaidStatus {
        STARTED,
        FINISHED,
        CANCELLED,
        CANCELLED_BY_ADMIN
    }

    // events
    event RaidCreated(
        string VerificationKey,
        address buybackAddress,
        uint256 RaidID,
        address Creator,
        uint256 RaidTime,
        uint BurnPercentage
    );

    event RaidCancelled(uint256 RaidID, uint256 DepositAmount);
    event RaidFinished(
        uint256 RaidID,
        uint256 BurnedGini,
        uint256 SentToMarketingWallet,
        uint256 TotalEthSwapped,
        uint256 ethSwappedToBuybackToken,
        uint256 ethSwappedToGini,
        uint256 BuybackTokenBurned,
        uint256 BuybackTokenToRaiders,
        uint256 BuybackTokenPerRaider,
        address[] Raiders
    );
    event RaidCancelledByAdmin(uint256 RaidID);
    event RaidFinishEnabledByAdmin(uint256 RaidID);

    // variables
    address dead = address(0x000000000000000000000000000000000000dEaD);
    address public giniTokenAddress; // gini token address
    address public giniMW; //marketing wallet
    uint public giniFeePercentage; // 10000 = 100%, 1000 = 10%, 100 = 1%, 10 = 0.1%, 1 = 0.01% (The amount % of fee that will be taken from the buyback amount of projects)
    uint public giniBurnPercentage; // 10000 = 100%, 1000 = 10%, 100 = 1%, 10 = 0.1%, 1 = 0.01% (The amount % of the buyback amount for gini that will get burned, the rest will be sent to the marketing wallet)
    IUniswapV2Router02 public immutable uniswapV2Router;

    // structs
    struct RaidMapping {
        uint256 RaidID;
        uint256 DepositAmount;
        address BuybackAddress;
        address Creator;
        uint BurnPercentage;
        string VerificationKey;
        RaidStatus Status;
        bool finishEnabledByAdmin;
    }
    // mappings
    mapping(uint256 => RaidMapping) public raids;

    constructor(
        address uniswapRouter,
        address _giniTokenAddress,
        uint _giniFeePercentage, // 10000 = 100%, 1000 = 10%, 100 = 1%, 10 = 0.1%, 1 = 0.01%
        uint _giniBurnPercentage, // 10000 = 100%, 1000 = 10%, 100 = 1%, 10 = 0.1%, 1 = 0.01%
        address _giniMarketingWallet
    ) {
        transferOwnership(msg.sender);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapRouter);
        uniswapV2Router = _uniswapV2Router;

        giniTokenAddress = _giniTokenAddress;
        giniFeePercentage = _giniFeePercentage;
        giniBurnPercentage = _giniBurnPercentage;
        giniMW = _giniMarketingWallet;
    }

    // DONT INVOKE THIS FUNCTION DIRECTLY, USE THE GINI WEB APP
    // (INVALID VERIFICATION KEY WILL BE REJECTED AND YOU WILL LOSE YOUR DEPOSIT) (WARNING FOR ABUSERS)
    function createRaid(
        string calldata verificationKey,
        uint burnPercentage, // 10000 = 100%, 1000 = 10%, 100 = 1%, 10 = 0.1%, 1 = 0.01%
        address buybackAddress, // the token that we should buy back with the provided ETH amount
        uint256 raidID
    ) public payable {
        require(msg.value > 0, "You need to send some Ether");
        require(
            raids[raidID].DepositAmount == 0,
            "This raidID is already in use"
        );
        raids[raidID] = RaidMapping(
            raidID,
            msg.value,
            buybackAddress,
            msg.sender,
            burnPercentage, // 10000 = 100%, 1000 = 10%, 100 = 1%, 10 = 0.1%, 1 = 0.01%
            verificationKey,
            RaidStatus.STARTED,
            false
        );
        emit RaidCreated(
            verificationKey,
            buybackAddress,
            raidID,
            msg.sender,
            block.timestamp,
            burnPercentage
        );
    }

    //most important functions
    //this function will buy Buyback Tokens  + Gini with the provided ETH amount
    //it will burn some of the Gini and send the rest to the marketing wallet
    //it will burn some of the Buyback Tokens
    //it will send the rest of the Buyback Tokens to the raiders
    function finishRaid(
        uint256 raidID,
        address[] calldata raiderWallets
    ) public {
        RaidMapping storage raid = raids[raidID];
        require(raid.RaidID != 0, "Raid does not exist");
        require(
            raid.Status == RaidStatus.STARTED,
            "Raid is already finished or cancelled"
        );
        if (msg.sender != raid.Creator) {
            require(
                raid.finishEnabledByAdmin == true,
                "Raid Finish is not enabled by for others than the creator currently"
            );
        }

        raid.Status = RaidStatus.FINISHED;
        // gini fee (we buy gini with this amount)
        uint256 giniFeeAmount = (raid.DepositAmount * giniFeePercentage) /
            10000;
        // buyback amount (we buy back the token with this amount)
        uint256 buybackAmount = raid.DepositAmount - giniFeeAmount;
        // buy gini
        uint256 giniAmount = swapEthForTokens(giniTokenAddress, giniFeeAmount);
        // buy back token
        uint256 buybackTokenAmount = swapEthForTokens(
            raid.BuybackAddress,
            buybackAmount
        );
        // burn buybackTokens
        uint256 burnAmount = (buybackTokenAmount * raid.BurnPercentage) / 10000;
        // amounts for the raiders
        uint256 raidersAmount = buybackTokenAmount - burnAmount;
        // calculate the amount for each raider
        uint256 raiderAmount = 0;
        if (raiderWallets.length > 0) {
            raiderAmount = raidersAmount / raiderWallets.length;
            // send the buybackToken to the raiders (should be max 100 raiders because of gas limit)
            for (uint256 i = 0; i < raiderWallets.length; i++) {
                // approve the transfer for the raider
                address raider = raiderWallets[i];
                IERC20(raid.BuybackAddress).approve(raider, raiderAmount);
                IERC20(raid.BuybackAddress).transfer(
                    raiderWallets[i],
                    raiderAmount
                );
            }
        } else {
            // if there are no raiders, burn the tokens instead
            raidersAmount = 0;
            burnAmount += raidersAmount;
        }
        // burn the remaining tokens
        IERC20(raid.BuybackAddress).approve(dead, burnAmount);
        IERC20(raid.BuybackAddress).transfer(dead, burnAmount);

        // calculate burn amount for gini
        uint256 giniBurnAmount = (giniAmount * giniBurnPercentage) / 10000;
        // calculate the amount for MW (marketing wallet) for gini
        uint256 giniMarketingAmount = giniAmount - giniBurnAmount;
        // send the gini to the marketing wallet
        IERC20(giniTokenAddress).approve(giniMW, giniMarketingAmount);
        IERC20(giniTokenAddress).transfer(giniMW, giniMarketingAmount);
        // burn the remaining gini
        IERC20(giniTokenAddress).approve(dead, giniBurnAmount);
        IERC20(giniTokenAddress).transfer(dead, giniBurnAmount);
        emit RaidFinished(
            raid.RaidID,
            giniBurnAmount,
            giniMarketingAmount,
            raid.DepositAmount,
            giniFeeAmount,
            buybackAmount,
            burnAmount,
            raidersAmount,
            raiderAmount,
            raiderWallets
        );
    }

    //swaps ETH for tokens
    function swapEthForTokens(
        address tokenToBuy,
        uint256 ethAmount
    ) private returns (uint256 amountBought) {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = tokenToBuy;
        // make the swap
        uint256 balanceBefore = IERC20(tokenToBuy).balanceOf(address(this));
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: ethAmount
        }(
            0, // accept any amount of tokens as possible (we will check the balance after the swap)
            path,
            address(this),
            block.timestamp + 360
        );
        uint256 balanceAfter = IERC20(tokenToBuy).balanceOf(address(this));
        uint256 amountsBought_ = balanceAfter - balanceBefore;
        return amountsBought_;
    }

    // this lets anyone finish the raid if the creator is not responding
    function enableFinishByAdmin(uint256 raidID) public onlyOwner {
        RaidMapping storage raid = raids[raidID];
        require(raid.RaidID != 0, "Raid does not exist");
        require(raid.Status == RaidStatus.STARTED, "Raid is already finished");
        raid.finishEnabledByAdmin = true;
        emit RaidFinishEnabledByAdmin(raid.RaidID);
    }

    // this lets Gini owner cancel the raid and refund the deposit to the creator
    // Can only be invoked by Gini owner to prevent scams from admins of groups. (Quick rug pulls where they cancel the raid and take the deposit after the raid is finished)
    function cancelRaid(uint256 raidID) public onlyOwner {
        RaidMapping storage raid = raids[raidID];
        require(raid.RaidID != 0, "Raid does not exist");
        require(raid.Status == RaidStatus.STARTED, "Raid is already finished");
        raid.Status = RaidStatus.CANCELLED;
        // refund the deposit
        payable(raid.Creator).transfer(raid.DepositAmount);
        emit RaidCancelled(raid.RaidID, raid.DepositAmount);
    }

    function updateContractDetails(
        address _giniMarketingWallet,
        address _giniTokenAddress,
        uint _giniFeePercentage, // 10000 = 100%, 1000 = 10%, 100 = 1%, 10 = 0.1%, 1 = 0.01%
        uint _giniBurnPercentage // 10000 = 100%, 1000 = 10%, 100 = 1%, 10 = 0.1%, 1 = 0.01%
    ) public onlyOwner {
        giniTokenAddress = _giniTokenAddress;
        giniFeePercentage = _giniFeePercentage;
        giniBurnPercentage = _giniBurnPercentage;
        giniMW = _giniMarketingWallet;
    }

    function updateRaidSettins(
        uint256 raidID,
        uint _burnPercentage
    ) public payable onlyOwner {
        RaidMapping storage raid = raids[raidID];
        require(raid.RaidID != 0, "Raid does not exist");
        require(raid.Status == RaidStatus.STARTED, "Raid is already finished");
        require(
            msg.sender == raid.Creator,
            "Only creator can update the settings"
        );
        if (msg.value != 0) {
            raid.DepositAmount += msg.value;
        }
        if (_burnPercentage != 0) {
            raid.BurnPercentage = _burnPercentage;
        }
    }
}