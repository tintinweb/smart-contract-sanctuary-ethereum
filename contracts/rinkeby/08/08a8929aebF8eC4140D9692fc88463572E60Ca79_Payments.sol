// contracts/BoosterEnabledToken.sol
// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;

pragma solidity ^0.8.1;

import "./Minter.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

// import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
// import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

interface IUniswapV2Router02 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

interface MinterInterface {
    // function mintNewToken(address owner, uint256 idToMint) external;
    function mintPacks(
        uint256 projectid,
        string calldata name,
        string calldata symbol
    ) external returns (address packAddress);

    function mintNFT(
        // bool isJson,
        string calldata _uri,
        // string calldata _storefronturi,
        uint256 projectid,
        string calldata name,
        string calldata symbol
    ) external returns (address nftAddres);
}

interface PackBorderInterface {
    // function mintNewToken(address owner, uint256 idToMint) external;
    function useBorder(uint256 borderId) external;
}

interface SeapadInterface {
    function getProjectItems(uint256 projectId)
        external
        view
        returns (
            uint256[] memory,
            address contractAddress,
            uint256 pricePerPack
        );

    function topUp(
        uint256 amount,
        uint256 projectId,
        uint256 packSoldID
    ) external;
    // BatchMint
}

interface WethInterface {
    function withdraw(uint256) external;

    function deposit() external payable;
}

import {SeapadHelper} from "./SeapadHelper.sol";

contract Payments is Ownable {
    VRFCoordinatorV2Interface COORDINATOR;
    address public chainLinkToken;
    address public parentAddress;

    uint256 public CHAINLINK_FEE_FOR_PACK_GEN; //1 LINK
    uint256 public CHAINLINK_MINIMUM_BASE_FEE;
    uint256[] public currentLanes;
    modifier onlyParentContract() {
        _;
        require(
            msg.sender == parentAddress || msg.sender == owner(),
            "Only parent contract can call this (Payments.sol)."
        );
    }
    IUniswapV2Router02 private immutable uniswapV2Router;
    // IUniswapV2Router02 uniswapV2Router;

    struct Projects {
        address owner;
        mapping(uint256 => PaymentMethod) paymentMethod;
        uint256 basePayment;
        mapping(uint256 => PaymentMethod) projectPaymentMethods; //projectID
        uint256[] paymentMethods;
        bool validProject;
    }

    struct PaymentMethod {
        uint256 paymentMethodID;
        address paymentMethodAddress;
        uint256 feePercentage;
        uint256 balance;
        bool valid;
    }

    receive() external payable {}

    struct PaymentMethods {
        bool valid;
        address paymentMethodAddress; //address 0x0 is valid as main payment method
        uint256 defaultFeePercentage;
        bool keep;
        uint256 currentSiteBal;
        uint256 totalSiteEarned;
        uint256 decimals;
    }
    mapping(uint256 => Projects) public projects;
    mapping(uint256 => PaymentMethods) public paymentMethods;
    mapping(uint256 => bytes32) public lanes;

    function getProjectPaymentDetails(uint256 projectid, uint256 paymentMethod)
        public
        view
        returns (
            uint256 pricePerPackInBaseToken,
            address paymentMethodAddress,
            address basePaymentMethodAddress,
            bool isBaseToken,
            uint256 FEE_PERCENTAGE_SAVED_USING_THIS_METHOD,
            uint256 basePaymentID,
            bool keeper,
            uint256 _paymentMethodID
        )
    {
        // Projects storage project = projects[projectid];
        // SeapadPayments seapadPayments = SeapadPayments(paymentAddress);
        // pricePerPackInBaseToken = project.pricePerPack;
        uint256 tmpProjectID = projectid;
        (, , pricePerPackInBaseToken) = SeapadInterface(parentAddress)
            .getProjectItems(projectid);
        bool valid;
        uint256 paymentMethodID = paymentMethod;
        (
            ,
            paymentMethodAddress,
            FEE_PERCENTAGE_SAVED_USING_THIS_METHOD,
            ,
            valid,
            isBaseToken
        ) = getProjectPaymentMethod(tmpProjectID, paymentMethodID);
        require(valid, "Invalid payment method");

        (, uint256 basePaymentMethodID) = getProjectPaymentMethods(
            tmpProjectID
        );
        bool keep;
        (, basePaymentMethodAddress, , keep, , , ) = getPaymentMethod(
            basePaymentMethodID
        );

        return (
            pricePerPackInBaseToken,
            paymentMethodAddress,
            basePaymentMethodAddress,
            isBaseToken,
            FEE_PERCENTAGE_SAVED_USING_THIS_METHOD,
            basePaymentMethodID,
            keep,
            paymentMethodID
        );
    }

    function getPackPrice(
        uint256 projectid,
        uint256 paymentMethod,
        uint256 slippage,
        uint256 basePercentage
    )
        public
        view
        returns (
            uint256 packPriceAfterFeeRemoved,
            uint256 packPriceWithoutFeeRemoved,
            uint256 removedFeeAmount,
            uint256 removedFeePercentage,
            // uint256 remainderFeePercentageFromPackSaleToSeapad,
            uint256 feeAmountRemainingForSeapadFromOriginalPackPrice
        )
    {
        (
            uint256 _packPriceWithoutFeeRemoved,
            address paymentMethodAddress,
            address basePaymentMethodAddress,
            bool isBasePayment,
            uint256 FEE_PERCENTAGE_SAVED_USING_THIS_METHOD,
            ,
            ,

        ) = getProjectPaymentDetails(projectid, paymentMethod);
        // `ProjectsP2 storage projectp2 = projectsP2[tmpProjectID];
        uint256 slippage2 = slippage;
        // uint projectid2 = projectid;
        //removes initial fee from pack price
        uint256 FEE_TO_REMOVE = (FEE_PERCENTAGE_SAVED_USING_THIS_METHOD *
            _packPriceWithoutFeeRemoved) / 10000;
        uint256 REMAINDER_FEE_PERCENTAGE = basePercentage -
            FEE_PERCENTAGE_SAVED_USING_THIS_METHOD;
        uint256 FEE_REMAINING_FOR_SEAPAD = (REMAINDER_FEE_PERCENTAGE *
            _packPriceWithoutFeeRemoved) / 10000;

        uint256 _packPriceAfterFeeRemoved = _packPriceWithoutFeeRemoved +
            ((_packPriceWithoutFeeRemoved * slippage2) / 10000) -
            FEE_TO_REMOVE;

        if (!isBasePayment) {
            bool useEthMiddle = paymentMethodAddress !=
                uniswapV2Router.WETH() &&
                basePaymentMethodAddress != uniswapV2Router.WETH()
                ? true
                : false;

            uint256 result = getEstimatedTokenNeededToRecieveOtherToken(
                paymentMethodAddress,
                basePaymentMethodAddress,
                _packPriceWithoutFeeRemoved,
                useEthMiddle
            )[0];
            FEE_TO_REMOVE =
                (FEE_PERCENTAGE_SAVED_USING_THIS_METHOD * result) /
                10000;
            FEE_REMAINING_FOR_SEAPAD =
                (REMAINDER_FEE_PERCENTAGE * result) /
                10000;
            // uint256 slippageFee = (result * slippage2) / 10000;
            _packPriceAfterFeeRemoved =
                result +
                ((result * slippage2) / 10000) -
                FEE_TO_REMOVE;
            _packPriceWithoutFeeRemoved = result;
        }

        return (
            _packPriceAfterFeeRemoved,
            _packPriceWithoutFeeRemoved,
            FEE_TO_REMOVE,
            FEE_PERCENTAGE_SAVED_USING_THIS_METHOD,
            // REMAINDER_FEE_PERCENTAGE,
            FEE_REMAINING_FOR_SEAPAD
        );
    }

    // function topUpSubscription(
    //     uint64 subId,
    //     uint256 projectID,
    //     uint256 packID,
    //     uint256 amount,
    //     address vrfCordinator
    // ) public {
    //     LinkTokenInterface(chainLinkToken).transferFrom(
    //         msg.sender,
    //         address(this),
    //         amount
    //     );
    //     LinkTokenInterface(chainLinkToken).transferAndCall(
    //         vrfCordinator,
    //         amount,
    //         abi.encode(subId)
    //     );
    //     SeapadInterface(parentAddress).topUp(amount, projectID, packID);
    // }

    function swapAndTransferTo(
        address swapAddressFrom,
        address swapAddressTo,
        address _owner,
        uint256 amount
    ) external {
        IERC20 token = IERC20(swapAddressTo);
        IERC20 tokenFrom = IERC20(swapAddressFrom);
        uint256 minAmt = uniswapV2Router.getAmountsOut(
            amount,
            SeapadHelper.getPathToTokenFromToken(swapAddressFrom, swapAddressTo)
        )[1];

        uint256 balBeforeTransfer = token.balanceOf(address(this));
        tokenFrom.approve(address(uniswapV2Router), amount);
        if (swapAddressTo == uniswapV2Router.WETH()) {
            //swapping tokens to WETH
            uniswapV2Router.swapExactTokensForETH(
                amount,
                minAmt,
                SeapadHelper.getPathToTokenFromToken(
                    swapAddressFrom,
                    swapAddressTo
                ),
                address(this),
                block.timestamp + 150
            );
        } else {
            //swapping tokens to other token
            address[] memory path = swapAddressFrom == uniswapV2Router.WETH()
                ? SeapadHelper.getPathToTokenFromToken(
                    uniswapV2Router.WETH(),
                    swapAddressTo
                )
                : SeapadHelper.getPathToTokenFromTokenThroughEth(
                    swapAddressFrom,
                    uniswapV2Router.WETH(),
                    swapAddressTo
                );

            minAmt = uniswapV2Router.getAmountsOut(amount, path)[1];
            uniswapV2Router
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    amount,
                    minAmt,
                    path,
                    address(this),
                    block.timestamp + 150
                );
        }

        uint256 balAfterTransfer = token.balanceOf(address(this));
        uint256 recieved = balAfterTransfer - balBeforeTransfer;
        token.transfer(_owner, recieved);
    }

    function calculateRandomnessChainlinkFee(
        uint32 totalCallbackFee,
        int256 ETHLINKpriceinwei,
        uint256 gaslanegwei
    ) public view returns (uint256) {
        require(lanes[gaslanegwei] != 0x0, "Invalid gas lane");
        uint256 totalCallbackFee2 = uint256(totalCallbackFee) * 10**9;
        uint256 fallbackprice = uint256(ETHLINKpriceinwei) / 1000000000; //in gwei.
        uint256 math1 = ((gaslanegwei * 10**9) *
            (uint256(totalCallbackFee2) / fallbackprice)) +
            CHAINLINK_MINIMUM_BASE_FEE;
        return math1;
    }

    function updateLanes(uint256[] calldata lane, bytes32[] calldata hashKeys)
        public
        onlyOwner
    {
        for (uint256 index = 0; index < lane.length; index++) {
            bytes32 hashKey = hashKeys[index];
            lanes[lane[index]] = hashKey;
        }
        currentLanes = lane;
    }

    // function getGasLanes() public view returns {
    //     return lanes;
    // }
    function getGasLane(uint256 gaslane) public view returns (bytes32) {
        return lanes[gaslane];
    }

    constructor(
        address parentAddress_,
        address _chainlinkToken,
        address _routerAddress,
        uint256 _CHAINLINK_FEE_FOR_PACK_GEN,
        uint256 _CHAINLINK_MINIMUM_BASE_FEE_IN_WEI
    ) {
        chainLinkToken = _chainlinkToken;
        CHAINLINK_FEE_FOR_PACK_GEN = _CHAINLINK_FEE_FOR_PACK_GEN;
        parentAddress = address(parentAddress_);
        CHAINLINK_MINIMUM_BASE_FEE = _CHAINLINK_MINIMUM_BASE_FEE_IN_WEI;
        uniswapV2Router = IUniswapV2Router02(_routerAddress);
    }

    function updateContractDetails(
        address newParentContract,
        uint256 _CHAINLINK_FEE_FOR_PACK_GEN,
        uint256 _CHAINLINK_MINIMUM_BASE_FEE
    ) public onlyOwner {
        parentAddress = newParentContract;
        CHAINLINK_FEE_FOR_PACK_GEN = _CHAINLINK_FEE_FOR_PACK_GEN;
        CHAINLINK_MINIMUM_BASE_FEE = _CHAINLINK_MINIMUM_BASE_FEE;
    }

    //inserts project and purhcases chainlink tokens to be able to generate the packs with oracle, and sends it back to parentContract.
    function insertNewProject(
        address owner,
        uint256 projectId,
        uint256[] calldata paymentMethods_,
        uint256 basePayment,
        uint256 slippage
    ) public payable onlyParentContract {
        require(!projects[projectId].validProject, "Project already exists.");
        projects[projectId].owner = owner;
        projects[projectId].validProject = true;
        bool validBasePayment;
        for (uint256 index = 0; index < paymentMethods_.length; index++) {
            uint256 paymentMethod = paymentMethods_[index];
            require(paymentMethod != 0, "Payment method cannot be 0.");
            PaymentMethods memory pm = paymentMethods[paymentMethod];
            require(pm.valid, "Payment method is not valid.");
            if (basePayment == paymentMethod) {
                validBasePayment = true;
            }
            PaymentMethod storage pmm = projects[projectId]
                .projectPaymentMethods[paymentMethod];
            pmm.balance = 0;
            pmm.paymentMethodID = paymentMethod;
            pmm.paymentMethodAddress = pm.paymentMethodAddress;
            pmm.feePercentage = pm.defaultFeePercentage;
            pmm.valid = true;
        }
        uint256 MINETHNEEDED = getEstimatedETHforToken(
            chainLinkToken,
            CHAINLINK_FEE_FOR_PACK_GEN
        )[0];
        //slippage to eth amt.
        uint256 MINETHNEEDEDWITHSLIPPAGE = ((MINETHNEEDED * slippage) / 10000) +
            MINETHNEEDED;
        require(
            msg.value >= MINETHNEEDEDWITHSLIPPAGE,
            "need more eth to do transfer."
        );
        uint256 balEfter = buyTokensWithETH(
            MINETHNEEDEDWITHSLIPPAGE,
            CHAINLINK_FEE_FOR_PACK_GEN,
            chainLinkToken,
            msg.value
        );
        require(validBasePayment, "Base payment method is not valid1.");
        require(
            IERC20(chainLinkToken).balanceOf(address(this)) >=
                CHAINLINK_FEE_FOR_PACK_GEN,
            "Could not get enough chainlink!"
        );
        IERC20(chainLinkToken).transfer(
            parentAddress,
            CHAINLINK_FEE_FOR_PACK_GEN
        );
        projects[projectId].basePayment = basePayment;
        projects[projectId].paymentMethods = paymentMethods_;
        paymentMethods[0].currentSiteBal += balEfter; //balance after in ETH.
        paymentMethods[0].totalSiteEarned += balEfter; //balance after in ETH (profit to us).
    }

    //get payment method by id
    function getPaymentMethod(uint256 paymentMethodId)
        public
        view
        returns (
            bool valid,
            address paymentMethodAddress, //address 0x0 is valid as main payment method
            uint256 defaultFeePercentage,
            bool keep,
            uint256 currentSiteBal,
            uint256 totalSiteEarned,
            uint256 decimals
        )
    {
        PaymentMethods memory paymentMethod = paymentMethods[paymentMethodId];
        require(paymentMethod.valid, "Invalid payment method.");
        return (
            paymentMethod.valid,
            paymentMethod.paymentMethodAddress,
            paymentMethod.defaultFeePercentage,
            paymentMethod.keep,
            paymentMethod.currentSiteBal,
            paymentMethod.totalSiteEarned,
            paymentMethod.decimals
        );
    }

    function getProjectPaymentMethod(uint256 projectid, uint256 paymentMethod)
        public
        view
        returns (
            uint256 paymentMethodID,
            address paymentMethodAddress,
            uint256 feePercentage,
            uint256 balance,
            bool valid,
            bool isBasePayment
        )
    {
        Projects storage project = projects[projectid];
        PaymentMethod memory paymentMethodStruct = project
            .projectPaymentMethods[paymentMethod];
        isBasePayment = paymentMethod == project.basePayment;
        return (
            paymentMethodStruct.paymentMethodID,
            paymentMethodStruct.paymentMethodAddress,
            paymentMethodStruct.feePercentage,
            paymentMethodStruct.balance,
            paymentMethodStruct.valid,
            isBasePayment
        );
    }

    //get payment methods array of uints
    function getProjectPaymentMethods(uint256 projectid)
        public
        view
        returns (uint256[] memory _paymentMethods, uint256 basePayment)
    {
        Projects storage project = projects[projectid];
        return (project.paymentMethods, project.basePayment);
    }

    function editSitePaymentMethods(
        uint256[] calldata paymentMethods_,
        address[] calldata addresses,
        uint256[] calldata decimals,
        bool[] calldata valid,
        bool[] calldata keeper,
        uint256[] calldata fees
    ) public onlyOwner {
        require(
            paymentMethods_.length == addresses.length &&
                paymentMethods_.length == decimals.length &&
                paymentMethods_.length == addresses.length &&
                paymentMethods_.length == valid.length &&
                paymentMethods_.length == keeper.length &&
                paymentMethods_.length == fees.length,
            "Invalid lengths provided"
        );
        for (uint256 index = 0; index < paymentMethods_.length; index++) {
            uint256 _paymentMethod = paymentMethods_[index];
            PaymentMethods storage paymentm = paymentMethods[_paymentMethod];
            // PaymentMethods paymentMethods = PaymentMethods[paymentMethods_.length];
            paymentm.paymentMethodAddress = addresses[index];
            paymentm.decimals = decimals[index];
            paymentm.valid = valid[index];
            paymentm.keep = keeper[index];
            paymentm.paymentMethodAddress = addresses[index];
            paymentm.defaultFeePercentage = fees[index];
            // paymentMethods
        }
    }

    //recieve token , and send remaining back.
    function buyTokensWithETH(
        uint256 amountEthToSend,
        uint256 minTokenAmountToRecieve,
        address tokenAddressToRecieve,
        uint256 totalEthAmt
    ) public returns (uint256) {
        // uint256 ETH_TO_SPEND = getEstimatedETHforToken(minTokenAmountToRecieve, amountEthToSend)[0];
        uniswapV2Router.swapExactETHForTokens{value: amountEthToSend}(
            minTokenAmountToRecieve,
            SeapadHelper.getPathForToken(
                tokenAddressToRecieve,
                uniswapV2Router.WETH()
            ),
            address(this), //goes back to parent contract.
            block.timestamp + 150
        );
        uint256 balEfter = totalEthAmt - amountEthToSend;
        // address payable sender = parmentAddress;
        // payable(parentAddress).transfer(balEfter);
        return balEfter;
    }

    function buyLinkToken(
        address tokenToConvertFrom,
        uint256 fullPaymentAmount,
        uint256 amountToTokenToBuy,
        address linkTokenAddress,
        uint256 slippage,
        address vrfCoordinatorAddress
    ) public payable onlyParentContract returns (uint256, uint64) {
        IERC20 token = IERC20(tokenToConvertFrom);
        LinkTokenInterface LINKTOKEN = LinkTokenInterface(linkTokenAddress);
        address tokenToConvertFrom_ = tokenToConvertFrom;
        uint256 amountToTokenToBuy_ = amountToTokenToBuy;
        address _linkTokenAddress = linkTokenAddress;
        uint256 _fullPaymentAmount = fullPaymentAmount;
        uint256 slippage2 = (amountToTokenToBuy * slippage) / 10000;
        uint256 recievedCl = 0;
        //this is how much TOKENS we will need to purchase the ETH required to purchase the chainlink tokens.

        uint256 estimated = tokenToConvertFrom_ ==
            address(uniswapV2Router.WETH())
            ? getEstimatedETHforToken(
                linkTokenAddress,
                amountToTokenToBuy_ + slippage2
            )[0]
            : getEstimatedTokenNeededToRecieveOtherToken(
                tokenToConvertFrom_,
                linkTokenAddress,
                amountToTokenToBuy_ + slippage2,
                true
            )[0];
        uint256 tokensUsed = 0;
        token.transferFrom(msg.sender, address(this), _fullPaymentAmount);
        //if this payment is made with WETH, we only need to purchase chainlink tokens.
        if (tokenToConvertFrom_ == address(uniswapV2Router.WETH())) {
            //this is weth payment.
            require(
                _fullPaymentAmount >= estimated,
                "not enough eth to buy tokens."
            );
                 uint256 clb = LINKTOKEN.balanceOf(address(this));
            //
            uniswapV2Router.swapExactETHForTokens{value: estimated}(
                amountToTokenToBuy_,
                SeapadHelper.getPathForToken(
                    _linkTokenAddress,
                    uniswapV2Router.WETH()
                ),
                address(this),
                block.timestamp + 150
            ); // spend 10
            require(
                token.transferFrom(
                    address(this),
                    parentAddress,
                    (_fullPaymentAmount - estimated)
                ),
                "token transferFrom failed."
            );
            recievedCl = LINKTOKEN.balanceOf(address(this)) - clb;
            tokensUsed = estimated;
        } else {
            //if payment token is not WETH, we need to purchase LINK via TOKEN->ETH->LINK.
            string memory errorMessage = string(
                abi.encodePacked(
                    "Payment needs at least least: ",
                    SeapadHelper.uint2str(estimated),
                    " wei tokens to buy eth!"
                )
            );
            require(_fullPaymentAmount >= estimated, errorMessage);

            IERC20(tokenToConvertFrom_).approve(
                address(uniswapV2Router),
                estimated
            );
            // 1
            uint256 clb = LINKTOKEN.balanceOf(address(this));
            uniswapV2Router.swapExactTokensForTokens(
                estimated,
                amountToTokenToBuy_,
                SeapadHelper.getPathToTokenFromTokenThroughEth(
                    tokenToConvertFrom_,
                    uniswapV2Router.WETH(),
                    _linkTokenAddress
                ),
                address(this),
                block.timestamp + 150
            );
            //recieved balance of clb
            // 11 - 1 = 10
            recievedCl = LINKTOKEN.balanceOf(address(this)) - clb;
            uint256 balanceAfterToken = _fullPaymentAmount - estimated;
            IERC20(tokenToConvertFrom_).transfer(
                parentAddress,
                balanceAfterToken
            );
            tokensUsed = estimated;
        }
        uint64 subsciptionID = createSubscriptionAndTopUpBalance(
            recievedCl,
            vrfCoordinatorAddress,
            LINKTOKEN
        );
        return (tokensUsed, subsciptionID);
    }

    function createSubscriptionAndTopUpBalance(
        uint256 amountOfLinkToTopUp,
        address vrfCoordinator,
        LinkTokenInterface LinkToken
    ) private returns (uint64 subscriptionID) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        subscriptionID = COORDINATOR.createSubscription();
        COORDINATOR.addConsumer(subscriptionID, parentAddress);
        LinkToken.transferAndCall(
            address(COORDINATOR),
            amountOfLinkToTopUp,
            abi.encode(subscriptionID)
        );
        COORDINATOR.requestSubscriptionOwnerTransfer(
            subscriptionID,
            parentAddress
        );
        return subscriptionID;
    }

    function getEstimatedTokenNeededToRecieveOtherToken(
        address inputToken,
        address outputToken,
        uint256 outputTokensAmountToGetPriceFor,
        bool throughETH
    ) public view returns (uint256[] memory) {
        return
            uniswapV2Router.getAmountsIn(
                outputTokensAmountToGetPriceFor,
                throughETH
                    ? SeapadHelper.getPathToTokenFromTokenThroughEth(
                        inputToken,
                        uniswapV2Router.WETH(),
                        outputToken
                    )
                    : SeapadHelper.getPathToTokenFromToken(
                        inputToken,
                        outputToken
                    )
            );
    }

    function getEstimatedTokenForETH(
        address token,
        uint256 amountOfETHToConvert
    ) public view returns (uint256[] memory) {
        return
            uniswapV2Router.getAmountsIn(
                amountOfETHToConvert,
                SeapadHelper.getPathToEth(token, uniswapV2Router.WETH())
            );
    }

    function getEstimatedETHforToken(
        address token,
        uint256 amountOfTokensToRecieve
    ) public view returns (uint256[] memory) {
        return
            uniswapV2Router.getAmountsIn(
                amountOfTokensToRecieve,
                SeapadHelper.getPathForToken(token, uniswapV2Router.WETH())
            );
    }

    function getEstimatedTokenRecieveForEth(
        address token,
        uint256 amountOfTokensToRecieve
    ) public view returns (uint256[] memory) {
        return
            uniswapV2Router.getAmountsOut(
                amountOfTokensToRecieve,
                SeapadHelper.getPathForToken(token, uniswapV2Router.WETH())
            );
    }

    function isValidProject(uint256 index)
        private
        view
        returns (bool validProject)
    {
        require(projects[index].validProject, "Invalid project");
        return true;
    }

    function isValidCaller(uint256 projectrid)
        private
        view
        returns (bool validProject)
    {
        require(
            projects[projectrid].owner == tx.origin || tx.origin == owner()
        );
        return true;
    }

    function withdrawTokens(uint256 amt, address tokenAddress)
        public
        onlyOwner
    {
        IERC20 t = IERC20(tokenAddress);
        t.transfer(owner(), amt);
    }

    function withdrawEth(uint256 amt) public onlyOwner {
        payable(msg.sender).transfer(amt);
    }
}

pragma solidity ^0.8.1;
// SPDX-License-Identifier: MIT
library SeapadHelper {
    function toAsciiString(address x) public pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) public pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function uint2str(uint256 _i)
        public
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function stringToBytes32(string memory source)
        public
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function getPathToTokenFromTokenThroughEth(
        address inputToken,
        address wethAddress,
        address outputToken
    ) public pure returns (address[] memory) {
        address[] memory path = new address[](3);
        path[0] = inputToken;
        path[1] = wethAddress;
        path[2] = outputToken;
        return path;
    }

    function getPathToTokenFromToken(address inputToken, address outputToken)
        public
        pure
        returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = inputToken;
        path[1] = outputToken;
        return path;
    }

    function getPathToEth(address token, address wethAddress)
        public
        pure
        returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = wethAddress;
        return path;
    }

    function getPathForToken(address token, address wethAddress)
        public
        pure
        returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = wethAddress;
        path[1] = address(token);
        return path;
    }
}

// contracts/BoosterEnabledToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol";

interface Parent {
    struct PacksBought {
        uint256 projectID;
        uint256 packSoldID;
        address purchasedBy;
        address openedBy;
        address ownedBy;
        uint256[] wonItems;
        uint256[] itemAmtArr;
        uint256 totalPaid;
        address currencyPaid;
        uint256 ownerRecieved;
        address ownerCurrency;
        bool minted;
        bytes32 requestid;
        uint256 randomness;
        uint256 reservedLINK;
    }

    function openPack(uint256 projectid, uint256 packSoldID_)
        external
        returns (uint256[] calldata wonItems);

    function getPacksSold(uint256 projectid, uint256 packSoldID_)
        external
        view
        returns (PacksBought memory);

    function updatePackOwner(
        uint256 projectid,
        uint256 packSoldID_,
        address newOwner,
        address from
    ) external;

    function packRecievedImages(uint256 projectId)
        external
        view
        returns (bool recieved);

    function getProjectUris(uint256 projectId)
        external
        view
        returns (string memory unopenedUri, string memory openedUri);
}

contract Pack is ERC721, Ownable {
    string public _uriOpened = "";
    address public parent;
    uint256 private projectid;
    bool public opened = false;
    string private baseExtension = ".json";
    string pendingUri = "https://cdn.seapad.io/pending.json";
    string public _uri = "";

    function toString(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        str = string(bstr);
    }

    modifier onlyParentContact() {
        _;
        require(
            msg.sender == parent || msg.sender == owner(),
            "Only parent contract can call this (Pack.sol)."
        );
    }
    struct OpenedPack {
        bool opened;
    }
    mapping(uint256 => OpenedPack) private openedPacks;

    // function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
    // }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        Parent.PacksBought memory pack = Parent(parent).getPacksSold(
            projectid,
            tokenId
        );
        //if openRequested then packs are not transfarabele, only if to is the dead wallet
        //if minted packs are not transfarebble
        if (pack.requestid != bytes32(0)) {
            require(to == address(0), "Pack is open, cannot transfer");
        }

        Parent p = Parent(parent);
        p.updatePackOwner(projectid, tokenId, to, from);
    }

    constructor(
        // string memory thisUri,
        // string memory uriOpened,
        address _parent,
        uint256 _projectid,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        parent = _parent;
        projectid = _projectid;
        transferOwnership(_parent);
        // _uri = thisUri;
        // _uriOpened = uriOpened;
    }

    function packRecievedImages() public view returns (bool recieved) {
        Parent parentContract = Parent(parent);
        return parentContract.packRecievedImages(projectid);
    }

    function burnPack(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender ||
                msg.sender == parent ||
                msg.sender == owner(),
            "you cant burn this pack"
        );
        _burn(tokenId);
    }

    function packOpened(uint256 packid) public view returns (bool) {
        Parent parentContract = Parent(parent);
        Parent.PacksBought memory pack = parentContract.getPacksSold(
            projectid,
            packid
        );
        return pack.minted;
    }

    function openPack(uint256 packid) public {
        Parent parentContract = Parent(parent);
        parentContract.openPack(projectid, packid);
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
        Parent parentContract = Parent(parent);
        (string memory unopenedUri, string memory openedUri) = parentContract
            .getProjectUris(projectid);

        if (bytes(unopenedUri).length > 0) {
            if (packOpened(tokenId)) {
                return
                    bytes(openedUri).length > 0
                        ? string(
                            abi.encodePacked(
                                openedUri,
                                toString(tokenId),
                                baseExtension
                            )
                        )
                        : pendingUri;
            } else {
                return
                    bytes(unopenedUri).length > 0
                        ? string(
                            abi.encodePacked(
                                unopenedUri,
                                toString(tokenId),
                                baseExtension
                            )
                        )
                        : pendingUri;
            }
        } else {
            return pendingUri;
        }
    }

    function updateParentContract(address _newParentContract) public onlyOwner {
        parent = _newParentContract;
    }

    function contractURI() public pure returns (string memory) {
        return "https://cdn.seapad.io/storefront.json";
    }

    function mintNewToken(address owner, uint256 idToMint)
        public
        onlyParentContact
    {
        _mint(owner, idToMint);
    }
}

// contracts/BoosterEnabledToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface Launcher {
    function getStoreFront(uint256) external view returns (string memory);
}

interface Redeemables {
    function isValidItem(uint256 itemID, address contractAddress)
        external
        view
        returns (
            string memory itemName,
            string memory itemURI,
            bool enabled,
            uint256 amountTimesRedeemed
        );
}

contract NFT is ERC721, Ownable {
    address public parent;
    address public parentOwner;
    string public storefronturl;
    bool public isJson = false;
    string __uri;
    uint256[] freeMintIds;
    modifier onlySeapad() {
        _;
        require(
            msg.sender == parent || msg.sender == parentOwner,
            "Only SeaPad parent/owner can call this (NFT.sol)"
        );
    }
    modifier onlyParentContact() {
        _;
        require(
            msg.sender == parent,
            "Only parent contract can call this (NFT.sol)."
        );
    }

    function updateParentOwnerAndParent(address parent_, address parentOwner_)
        public
        onlySeapad
    {
        parent = parent_;
        parentOwner = parentOwner_;
    }
    address public seapadAddress;
    constructor(
        string memory thisUri,
        address _seapadAddress,
        string memory _name,
        string memory _symbol,
        address collectionOwner,
        bool _isJson
    ) ERC721(_name, _symbol) {
        // projectid = _projectid;
        parentOwner = _seapadAddress;
        __uri = thisUri;
        isJson = _isJson;
        transferOwnership(collectionOwner);
    }

    function updateParentContract(address _newParentContract)
        public
        onlySeapad
    {
        parent = _newParentContract;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    __uri,
                    uint2str(_tokenId),
                    isJson ? ".json" : ""
                )
            );
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        str = string(bstr);
    }

    // function _mint override
    function mintNewToken(address owner, uint256 idToMint) public returns(bool) {
        require(msg.sender == parentOwner, "Only parent owner can mint new token (NFT.sol)");
        _mint(owner, idToMint);
        return true;
    }
}

// contracts/BoosterEnabledToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./NFT.sol";
import "./Pack.sol";

contract Minter is Ownable {
    address public parent;

    // MODIFIERS
    modifier onlyParentContact() {
        _;
        require(
            msg.sender == parent || msg.sender == owner(),
            "Only parent contract can call this (Minter.sol)."
        );
    }

    constructor(address parentContract) {
        parent = parentContract;
        transferOwnership(msg.sender);
    }

    function updateParentContract(address newParent) public onlyOwner {
        parent = newParent;
    }

    function mintPacks(
        uint256 projectid,
        string calldata name,
        string calldata symbol
    ) public onlyParentContact returns (address packAddress) {
        Pack packs = new Pack(parent, projectid, name, symbol);
        // string memory thisUri, string memory uriOpened, address _parent, uint _projectid, string memory _name, string memory _symbol
        return address(packs);
    }

    function mintNFT(
        string memory _uri,
        address _seapadAddress,
        string memory _name,
        string memory _symbol,
        address collectionOwner,
        bool isJson
    ) public onlyParentContact returns (address nftAddres) {
        NFT token = new NFT(
            _uri,
            _seapadAddress,
            _name,
            _symbol,
            collectionOwner,
            isJson
        );
        return address(token);
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        str = string(bstr);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}