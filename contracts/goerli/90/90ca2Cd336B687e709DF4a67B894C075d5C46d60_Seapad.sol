// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.8.1;
import "./Minter.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {SeapadHelper} from "./SeapadHelper.sol";

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
        string calldata symbol,
        address _packCollectionOwner,
        address _seapadOwner
    ) external returns (address packAddress);

    function mintNFT(
        string memory _uri,
        address _seapadOwner,
        address _seapadAddress,
        string memory _name,
        string memory _symbol,
        address collectionOwner,
        bool isJson
    ) external returns (address nftAddres);
}

interface PackHelperInterface {
    // function mintNewToken(address owner, uint256 idToMint) external;
    function useBorder(uint256 borderId) external;

    function burnPack(uint256 tokenId) external;
}

interface SeapadPayments {
    function swapAndTransferTo(
        address swapAddressFrom,
        address swapAddressTo,
        address _owner,
        uint256 amount
    ) external;

    function insertNewProject(
        address owner,
        uint256 projectId,
        uint256[] calldata paymentMethods_,
        uint256 basePayment,
        uint256 slippage
    ) external payable;

    function getProjectPaymentDetails(uint256 projectid, uint256 paymentMethod)
        external
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
        );

    function getPackPrice(
        uint256 projectid,
        uint256 paymentMethod,
        uint256 slippage,
        uint256 basePercentage
    )
        external
        view
        returns (
            uint256 packPriceAfterFeeRemoved,
            uint256 packPriceWithoutFeeRemoved,
            uint256 removedFeeAmount,
            uint256 removedFeePercentage,
            // uint256 remainderFeePercentageFromPackSaleToSeapad,
            uint256 feeAmountRemainingForSeapadFromOriginalPackPrice
        );

    function getEstimatedTokenNeededToRecieveOtherToken(
        address inputToken,
        address outputToken,
        uint256 outputTokensAmountToGetPriceFor
    ) external view returns (uint256[] memory);

    function getProjectPaymentMethod(uint256 projectid, uint256 paymentMethod)
        external
        view
        returns (
            uint256 paymentMethodID,
            address paymentMethodAddress,
            uint256 feePercentage,
            uint256 balance,
            bool valid,
            bool isBasePayment
        );

    function getProjectPaymentMethods(uint256 projectid)
        external
        view
        returns (uint256[] memory _paymentMethods, uint256 basePayment);

    function calculateRandomnessChainlinkFee(
        uint32 totalCallbackFee,
        int256 ETHLINKpriceinwei,
        uint256 gaslanegwei
    ) external view returns (uint256);

    function getPaymentMethod(uint256 paymentMethodId)
        external
        view
        returns (
            bool valid,
            address paymentMethodAddress,
            uint256 defaultFeePercentage,
            bool keep,
            uint256 currentSiteBal,
            uint256 totalSiteEarned,
            uint256 decimals
        );

    function getEstimatedETHforToken(
        address token,
        uint256 amountOfTokensToRecieve
    ) external view returns (uint256);

    function getGasLane(uint256 gaslane) external view returns (bytes32);

    function buyLinkToken(
        address tokenToConvertFrom,
        uint256 fullPaymentAmount,
        uint256 amountToTokenToBuy,
        // address linkTokenAddress,
        uint256 slippage,
        address vrfCoordinatorAddress
    ) external payable returns (uint256, uint64);
}

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
}

interface WrapContract {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract Seapad is VRFConsumerBaseV2, ChainlinkClient {
    VRFCoordinatorV2Interface COORDINATOR;

    // uint64 s_subscriptionId;
    address vrfCoordinator;
    // bytes32 keyHash =
    //     0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;

    using Chainlink for Chainlink.Request;
    address oracle;
    bytes32 jobId;
    address owner;

    modifier onlyOwner() {
        require(owner == msg.sender, "NCA"); //not contract owner
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "0");
        owner = newOwner;
    }

    // uint256 CHAINLINK_RANDOMNESS_BASE_FEE;
    uint256 CHAINLINK_FEE_PACK_GENERATION;
    // uint256 public randomResult;

    uint256 PACK_LAUNCH_COST; //ETH
    uint16 PACK_SALE_BASE_FEE_PERCENTAGE = 1000; //10%
    uint32 CHAINLINK_CALLBACK_GAS = 200000;
    uint256 MAX_ITEMS_PER_PACK = 7;
    uint256 MAX_PACKS = 1000;
    bool LAUNCH_ENABLED = true;

    address paymentAddress = 0x243b8f7Da48e45995b5302E034Fb2A33f58aE6A1;
    address minterAddress = 0x243b8f7Da48e45995b5302E034Fb2A33f58aE6A1;
    address packBordersAddress = 0x028418706852fdcA5D194d443813c7F6abe19d04;
    address ELF = 0x028418706852fdcA5D194d443813c7F6abe19d04; //ETH_LINK_FEEDBACK_ADDRESS
    SeapadPayments Payments = SeapadPayments(paymentAddress);

    fallback() external payable {}

    uint256 projectAmount = 1;
    IUniswapV2Router02 private immutable uniswapV2Router;
    // IUniswapV2Router02 _uniswapV2Router;

    struct Projects {
        uint256 id;
        address owner;
        address contractAddress;
        address packAddress;
        uint256[] items;
        uint256[] wonItems;
        bool have0ItemID;
        bool claimed0ItemID;
        uint32 amountToPayOutPerPack;
        uint256 packsSold;
        uint256 packsForSale;
        mapping(uint256 => PacksBought) packsBought;
        mapping(address => bool) whitelist;
        bool whitelisted;
        string uri;
        uint256 pricePerPack;
        bool takeFeeFromPackPrice;
    }

    struct ProjectsP2 {
        uint256 id;
        string name;
        string symbol;
        string unopenedUri;
        string openedUri;
        uint256 launchTime;
        bool isJson;
        uint256 maxPurchaseAmountPerWallet;
        mapping(address => uint256) packsBought;
        uint256 BASE_FEE_PERCENTAGE;
        uint16 GAS_LANE;
        uint64[] SUBS_DONE;
        bool enabled;
    }

    struct PacksBoughtRequest {
        uint256 projectID;
        uint256 packSoldID;
        uint256 requestid;
        uint256[] randomness;
    }
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
        uint256 requestid;
        uint256[] randomness;
        uint256 reservedLINK;
        uint64 subscriptionID;
    }

    mapping(uint256 => Projects) public projects;
    mapping(uint256 => ProjectsP2) public projectsP2;
    mapping(uint256 => PacksBoughtRequest) packsBoughtRequests;
    mapping(address => uint256[]) public packCreators; //we need to keep track of which owners own which packs
    mapping(uint32 => uint32) public callbackGasFees;
    mapping(address => bool) cce; //customContractEnabled

    function updateCallbackGasFees(
        uint16[] calldata itemNumber,
        uint32[] calldata gasFee
    ) public onlyOwner {
        for (uint256 index = 0; index < itemNumber.length; index++) {
            callbackGasFees[itemNumber[index]] = gasFee[index];
        }
    }

    function getCallbackGasFee(uint32 itemAmount)
        public
        view
        returns (
            uint32 itemGasFees,
            uint32 callbackGasFee,
            uint32 totalCombined
        )
    {
        uint32 gasFees;
        for (uint32 index = 1; index <= itemAmount; index++) {
            uint32 gasFee = callbackGasFees[index];
            gasFees += gasFee;
        }
        return (
            gasFees,
            CHAINLINK_CALLBACK_GAS,
            (gasFees + CHAINLINK_CALLBACK_GAS)
        );
    }

    event ProjectCreated(
        uint256 projectID,
        address owner,
        address contractAddress,
        uint256[] items,
        uint32 amountToPayOutPerPack,
        uint256 packsForSale,
        string projectName
    );
    event ProjectCreatedP2(
        uint256 projectId,
        uint256 borderId,
        string packBackgroundImageUrl,
        uint256 pricePerPack,
        uint256 launchTime,
        bool isJson,
        address packAddress
    );
    event PackPurchase(
        uint256 projectID,
        uint256 packID,
        address purchasedBy,
        uint256 paymentAmount,
        uint256 paymentMethod,
        uint256 paymentAmountForOwner,
        address paymentMethodForOwner,
        uint256 paymentAmountForSeapad,
        address paymentMethodForSeapad
    );
    event OpenPackRequest(
        uint256 projectID,
        uint256 packID,
        address openedBy,
        uint256 requestid
    );
    event OpenedPack(
        uint256 projectID,
        uint256 packID,
        uint256[] itemsRecieved,
        address openedBy
    );
    event PackMinted(uint256 projectID, uint256 packID, address mintedBy);
    event ProjectUpdated(
        uint256 projectID,
        uint256 pricePerPack,
        bool whitelisted,
        address[] whitelistedAddresses,
        bool whitelistedAddressesEnabled,
        uint256 maxPackPerProject
    );
    event PackTransfered(
        uint256 projectID,
        uint256 packID,
        address from,
        address to
    );

    constructor(
        // string memory chainLinkJobId,
        address _vrfCordinator,
        address _oracle,
        address linkTokenAddress,
        address _routerAddress
    ) VRFConsumerBaseV2(_vrfCordinator) {
        owner = msg.sender;
        uniswapV2Router = IUniswapV2Router02(_routerAddress);
        setChainlinkToken(linkTokenAddress);
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCordinator);
        vrfCoordinator = _vrfCordinator;
        setChainlinkOracle(_oracle);
    }

    function updateContract(
        uint256 _PACK_LAUNCH_COST_ETH,
        uint256 _CHAINLINK_FEE_PACK_GENERATION,
        uint256 _MAX_ITEMS_PER_PACK,
        uint256 _MAX_PACKS,
        bool _LAUNCH_ENABLED,
        uint32 _CHAINLINK_CALLBACK_GAS_LIMIT,
        uint16 _PACK_SALE_BASE_FEE_PERCENTAGE,
        string calldata _jobId
    ) public onlyOwner {
        PACK_LAUNCH_COST = _PACK_LAUNCH_COST_ETH;
        PACK_SALE_BASE_FEE_PERCENTAGE = _PACK_SALE_BASE_FEE_PERCENTAGE;
        CHAINLINK_FEE_PACK_GENERATION = _CHAINLINK_FEE_PACK_GENERATION;
        MAX_ITEMS_PER_PACK = _MAX_ITEMS_PER_PACK;
        MAX_PACKS = _MAX_PACKS;
        LAUNCH_ENABLED = _LAUNCH_ENABLED;
        CHAINLINK_CALLBACK_GAS = _CHAINLINK_CALLBACK_GAS_LIMIT;
        jobId = SeapadHelper.stringToBytes32(_jobId);
    }

    function updateAddresses(
        address newMinterAddress, // MINTERADDRESS
        address newPackBorderAddress, //PACKbORDER
        address newPaymentAddress, //PAYMENT
        address _ELF, //ETH/LINK FEEDBACK ADDRESS
        address cc, //CUSTOM CONTRACT
        bool ccvalid //CUSTOM CONTRACT VALID
    ) public onlyOwner {
        minterAddress = newMinterAddress;
        packBordersAddress = newPackBorderAddress;
        paymentAddress = newPaymentAddress;
        // uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
        // COORDINATOR = VRFCoordinatorV2Interface(_VRFCOORDINATOR);
        ELF = _ELF;
        Payments = SeapadPayments(paymentAddress);
        cce[cc] = ccvalid;
    }

    function updateProject(
        uint256 projectid,
        uint256 pricePerPack,
        bool whitelisted,
        address[] calldata whitelistedAddresses,
        bool whitelistedAddressesEnabled,
        uint256 maxPackPerUser,
        uint256 baseFeePercentage,
        uint16 gasLane,
        bool eba //enabledbyADMIN
    ) public {
        isValidCaller(projectid);
        Projects storage project = projects[projectid];
        ProjectsP2 storage projects2 = projectsP2[projectid];
        project.pricePerPack = pricePerPack;
        project.whitelisted = whitelisted;
        projects2.maxPurchaseAmountPerWallet = maxPackPerUser;
        for (uint256 index = 0; index < whitelistedAddresses.length; index++) {
            project.whitelist[
                whitelistedAddresses[index]
            ] = whitelistedAddressesEnabled;
        }
        if (msg.sender == owner) {
            projects2.BASE_FEE_PERCENTAGE = baseFeePercentage;
            projects2.GAS_LANE = gasLane;
            projects2.enabled = eba;
        }
        emit ProjectUpdated(
            projectid,
            pricePerPack,
            whitelisted,
            whitelistedAddresses,
            whitelistedAddressesEnabled,
            maxPackPerUser
        );
    }

    function getContractDetails()
        public
        view
        returns (
            // uint256 RANDOMNESS_BASE_FEE,
            uint256 _PACK_GEN_CHAINLINK_FEE,
            uint256 _PACK_GEN_ETH_FEE,
            uint256 _PACK_SALE_FEE_PERCENTAGE,
            address _CONTRACT_OWNER,
            bytes32 _CHAINLINK_JOB_ID,
            bool _LAUNCH_ENABLED,
            uint32 _CHAINLINK_CALLBACK_GAS,
            address _ELF,
            address _ORACLE,
            address _MINTER_ADDDRESS,
            address _PAYMENT_ADDRESS,
            address _BORDERS_ADDRESS,
            address _VRF_CORDINATOR
        )
    {
        return (
            // CHAINLINK_RANDOMNESS_BASE_FEE,
            CHAINLINK_FEE_PACK_GENERATION,
            PACK_LAUNCH_COST,
            PACK_SALE_BASE_FEE_PERCENTAGE,
            owner,
            jobId,
            LAUNCH_ENABLED,
            CHAINLINK_CALLBACK_GAS,
            ELF,
            chainlinkOracleAddress(),
            minterAddress,
            paymentAddress,
            packBordersAddress,
            vrfCoordinator
        );
    }

    function getProjectItems(uint256 projectId)
        public
        view
        returns (
            uint256[] memory,
            address contractAddress,
            uint256 pricePerPack
        )
    {
        Projects storage project = projects[projectId];
        return (project.items, project.contractAddress, project.pricePerPack);
    }

    function removeItemFromWinnings(
        uint256 projectid,
        uint256 i,
        uint256 requestid
    ) private {
        Projects storage project = projects[projectid];

        PacksBoughtRequest storage pbr = packsBoughtRequests[requestid];
        PacksBought storage pb = project.packsBought[pbr.packSoldID];

        project.wonItems.push(project.items[i]);
        pb.wonItems.push(project.items[i]);
        pb.itemAmtArr.push(1);

        if (project.have0ItemID == true) {
            //if item is 0
            if (i == 0 && project.items[i] == 0) {
                //if not claimed 0
                if (project.claimed0ItemID == false) {
                    project.claimed0ItemID = true;
                    removeItem(i, projectid);
                } else {
                    revert("1");
                }
            } else {
                removeItem(i, projectid);
            }
        } else {
            removeItem(i, projectid);
        }
    }

    function removeItem(uint256 i, uint256 projectid) private {
        Projects storage project = projects[projectid];
        if (project.items.length >= 1) {
            project.wonItems.push(project.items[i]);
            project.items[i] = project.items[project.items.length - 1];
            project.items.pop();
        } else {
            revert("notItemsLeft");
        }
    }

    function purchasePack(
        uint256 projectid,
        uint256 paymentMethod,
        uint256 slippage
    ) public payable {
        isValidProject(projectid);
        // SeapadPayments seapadPayments = SeapadPayments(paymentAddress);
        Projects storage project = projects[projectid];
        ProjectsP2 storage projectP2 = projectsP2[projectid];
        // projectP2.BASE_FEE_PERCENTAGE
        // SeapadPayments Payments = SeapadPayments(paymentAddress);

        require(
            project.packsSold < project.packsForSale,
            "1" //"Project has no packs for sale"
        );
        require(
            projectP2.launchTime <= block.timestamp,
            "2" //launch time has not passed
        );
        require(
            projectP2.enabled,
            "3" //ADMIN HAS STOPPED THIS PROJECT
        );
        if (projectP2.maxPurchaseAmountPerWallet > 0) {
            require(
                projectP2.packsBought[msg.sender] <
                    projectP2.maxPurchaseAmountPerWallet,
                "4" //"You have already purchased this many packs"
            );
        }
        project.packsSold = project.packsSold + 1;
        // address projectOwner = project.owner;
        uint256 packsBoughtId = project.packsSold;
        PacksBought storage pb = project.packsBought[project.packsSold];
        uint256 tmpProjectID = projectid;
        // int256 latestCHainlinkAnswa = AggregatorInterface(ELF).latestAnswer();
        (, , uint32 totalCombined) = getCallbackGasFee(
            project.amountToPayOutPerPack
        );
        uint256 chainlinkFee = Payments.calculateRandomnessChainlinkFee(
            totalCombined,
            AggregatorInterface(ELF).latestAnswer(),
            uint256(projectP2.GAS_LANE)
        );
        pb.reservedLINK += chainlinkFee;
        uint256 tmpSlippage = slippage;

        pb.ownedBy = msg.sender;
        // return chainlinkFee;
        if (project.whitelisted) {
            // project.whitelist[msg.sender];
            require(project.whitelist[msg.sender] == true, "5"); //not whitelisted
        }
        (
            ,
            address paymentMethodAddress,
            ,
            ,
            ,
            ,
            ,
            uint256 _paymentMethod
        ) = Payments.getProjectPaymentDetails(projectid, paymentMethod);

        (
            uint256 pricePerPackInChoosenPaymentMethodAfterSavedFeeRemoved,
            ,
            ,
            ,
            uint256 feeAmountRemainingForSeapadFromOriginalPackPrice
        ) = Payments.getPackPrice(
                tmpProjectID,
                _paymentMethod,
                tmpSlippage,
                projectP2.BASE_FEE_PERCENTAGE
            );
        // }
        IERC20 token = IERC20(paymentMethodAddress); //token of the payment method

        //  if this is paid with ETH/POLYGON we need to wrap this to WETH/WPOLY
        if (
            paymentMethod == 1 &&
            msg.value == pricePerPackInChoosenPaymentMethodAfterSavedFeeRemoved
        ) {
            //this swaps to weth
            WrapContract(uniswapV2Router.WETH()).deposit{value: msg.value}();
        } else {
            // uint256 prevPrevBal = token.balanceOf(address(this));
            require(
                token.allowance(msg.sender, address(this)) >=
                    pricePerPackInChoosenPaymentMethodAfterSavedFeeRemoved,
                "6" // "Please allow contract to spend your tokens!"
            );
            //TRANSFER THE TOKENS TO US.
            token.transferFrom(
                msg.sender,
                address(this),
                pricePerPackInChoosenPaymentMethodAfterSavedFeeRemoved
            );
        }

        pb.totalPaid = pricePerPackInChoosenPaymentMethodAfterSavedFeeRemoved;
        pb.currencyPaid = paymentMethodAddress;

        // prevPrevBal = token.balanceOf(address(this)) - prevPrevBal;

        pb.projectID = tmpProjectID;
        pb.purchasedBy = msg.sender;
        Pack pack = Pack(payable(project.packAddress));
        pack.mintNewToken(msg.sender, packsBoughtId);

        token.approve(
            paymentAddress,
            pricePerPackInChoosenPaymentMethodAfterSavedFeeRemoved
        );

        (
            uint256 tokensSpentFromOriginalBalanceToGetChainlinkToken,
            uint64 subID
        ) = Payments.buyLinkToken(
                paymentMethodAddress,
                pricePerPackInChoosenPaymentMethodAfterSavedFeeRemoved,
                chainlinkFee,
                // chainlinkTokenAddress(),
                tmpSlippage,
                vrfCoordinator
            );
        COORDINATOR.acceptSubscriptionOwnerTransfer(subID);
        pb.subscriptionID = subID;
        //remaining tokens
        uint256 remainingTokens = pricePerPackInChoosenPaymentMethodAfterSavedFeeRemoved -
                tokensSpentFromOriginalBalanceToGetChainlinkToken -
                feeAmountRemainingForSeapadFromOriginalPackPrice;

        splitRemainingFunds(
            tmpProjectID,
            _paymentMethod,
            feeAmountRemainingForSeapadFromOriginalPackPrice,
            remainingTokens,
            pricePerPackInChoosenPaymentMethodAfterSavedFeeRemoved,
            token
        );
        // return project.packsSold;
        // pb.ownerRecieved = amountSentToOwner;
        // pb.ownerCurrency = ownerPaymentMethod;
    }

    function splitRemainingFunds(
        uint256 projectID,
        uint256 paymentMethod,
        uint256 feeAmountForSeapad,
        uint256 remainingAmountForOwner,
        uint256 totalPaymentAmtInChoosenPaymentMethod,
        IERC20 token
    ) private {
        Projects storage project = projects[projectID];
        (
            ,
            address paymentMethodAddress,
            address basePaymentMethodAddress,
            bool isBasePayment,
            ,
            ,
            bool keep,
            uint256 _paymentMethod
        ) = Payments.getProjectPaymentDetails(project.id, paymentMethod);

        // address projectOwner = project.owner;
        uint256 remainingForO = remainingAmountForOwner;
        uint256 remaindingForSeapad = feeAmountForSeapad;

        if (!keep) {
            token.transfer(paymentAddress, remaindingForSeapad);
            Payments.swapAndTransferTo(
                paymentMethodAddress,
                uniswapV2Router.WETH(),
                owner,
                remaindingForSeapad
            );
        } else {
            token.transfer(owner, remaindingForSeapad);
        }

        if (!isBasePayment) {
            token.transfer(paymentAddress, remainingForO);
            Payments.swapAndTransferTo(
                paymentMethodAddress,
                basePaymentMethodAddress,
                project.contractAddress,
                remainingForO
            );
        } else {
            token.transfer(project.contractAddress, remainingForO);
        }

        uint256 packBoughtID = project.packsSold;
        uint256 pricePerPackInChoosenPaymentMethodAfterSavedFeeRemoved = totalPaymentAmtInChoosenPaymentMethod;
        address _basePaymentMethodAddress = basePaymentMethodAddress;
        bool _keep = keep;
        // pbb.ownerRecieved = remainingAmountForOwner;
        // pbb.ownerCurrency = paymentMethodAddress;
        emit PackPurchase(
            project.id,
            packBoughtID,
            msg.sender,
            pricePerPackInChoosenPaymentMethodAfterSavedFeeRemoved,
            _paymentMethod,
            remainingForO,
            _basePaymentMethodAddress,
            remaindingForSeapad,
            _keep ? _basePaymentMethodAddress : uniswapV2Router.WETH()
        );
        PacksBought storage pb = project.packsBought[packBoughtID];
        pb.ownerRecieved = remainingForO;
        pb.ownerCurrency = _basePaymentMethodAddress;
        // return (remainingForO, _basePaymentMethodAddress);
    }

    function updatePackOwner(
        uint256 projectid,
        uint256 packId,
        address newOwner,
        address from
    ) external {
        Projects storage project = projects[projectid];
        require(msg.sender == project.packAddress);
        PacksBought storage pb = project.packsBought[packId];
        pb.ownedBy = newOwner;
        emit PackTransfered(project.id, packId, from, newOwner);
    }

    function emergencyGetRandomNumber(uint256 projectid, uint256 packSoldID)
        public
        onlyOwner
        returns (uint256)
    {
        return getRandomNumber(projectid, packSoldID);
    }

    function getPacksSold(uint256 projectid, uint256 packSoldID_)
        public
        view
        returns (PacksBought memory)
    {
        isValidProject(projectid);
        Projects storage project = projects[projectid];
        return project.packsBought[packSoldID_];
    }

    function mintOpenedPack(uint256 projectid, uint256 packSoldID_) public {
        Projects storage project = projects[projectid];
        PacksBought storage pb = project.packsBought[packSoldID_];
        NFT minter_ = NFT(project.contractAddress);
        require(pb.ownedBy == msg.sender, "1"); //notOwner
        require(pb.wonItems.length > 0, "2"); //itemsNotYetRecieved
        require(pb.minted == false, "3"); //alreadyMinted

        for (uint256 i = 0; i < pb.wonItems.length; i++) {
            minter_.mintNewToken(tx.origin, pb.wonItems[i]);
        }
        pb.minted = true;
        PackHelperInterface pack = PackHelperInterface(
            payable(project.packAddress)
        );

        pack.burnPack(packSoldID_);
        emit PackMinted(projectid, packSoldID_, msg.sender);
    }

    function openPack(uint256 projectid, uint256 packSoldID_) public {
        isValidProject(projectid);
        Projects storage project = projects[projectid];
        PacksBought storage pb = project.packsBought[packSoldID_];
        require(pb.purchasedBy != address(0), "1"); //invalid pack
        require(pb.openedBy == address(0), "2"); //already open
        require(pb.ownedBy == tx.origin, "3"); //notOwner
        // pb.minted = true;
        pb.openedBy = tx.origin;
        pb.requestid = getRandomNumber(pb.projectID, packSoldID_);
        emit OpenPackRequest(
            pb.projectID,
            packSoldID_,
            msg.sender,
            pb.requestid
        );
    }

    function getProjectUris(uint256 projectid)
        external
        view
        returns (string memory unopenedUri, string memory openedUri)
    {
        isValidProject(projectid);
        ProjectsP2 storage project = projectsP2[projectid];
        return (project.unopenedUri, project.openedUri);
    }

    function getRandomNumber(uint256 projectid, uint256 packSoldID)
        private
        returns (uint256)
    {
        Projects storage project = projects[projectid];
        ProjectsP2 storage projectp2 = projectsP2[projectid];

        PacksBought storage pb = project.packsBought[packSoldID];

        // uint32 callBackGasLimit = (100000 * project.amountToPayOutPerPack) +
        //     CHAINLINK_CALLBACK_GAS;
        (, , uint32 totalCombined) = getCallbackGasFee(
            project.amountToPayOutPerPack
        );

        uint16 requestConfirmations = 3;
        uint32 numWords = project.amountToPayOutPerPack;
        uint256 cost = Payments.calculateRandomnessChainlinkFee(
            totalCombined,
            AggregatorInterface(ELF).latestAnswer(),
            uint256(projectp2.GAS_LANE)
        );
        (uint96 bal, , , ) = COORDINATOR.getSubscription(pb.subscriptionID);
        require(
            bal >= cost,
            string(
                abi.encodePacked(
                    "TopUp,",
                    SeapadHelper.uint2str(cost),
                    ",",
                    SeapadHelper.uint2str(bal)
                )
            )
        ); //notenoughbalance
        uint256 requestId = COORDINATOR.requestRandomWords(
            Payments.getGasLane(projectp2.GAS_LANE),
            pb.subscriptionID,
            requestConfirmations,
            totalCombined,
            numWords
        );

        PacksBoughtRequest storage pbr = packsBoughtRequests[requestId];
        pb.packSoldID = packSoldID;
        pbr.projectID = projectid;
        pbr.packSoldID = packSoldID;
        pbr.requestid = requestId;

        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        PacksBoughtRequest storage pbr = packsBoughtRequests[requestId];
        Projects storage project = projects[pbr.projectID];
        ProjectsP2 storage projectP2 = projectsP2[pbr.projectID];
        PacksBought storage pb = project.packsBought[pbr.packSoldID];
        pb.randomness = randomWords;
        pbr.randomness = randomWords;
        generateWinnings(pbr.projectID, randomWords, requestId);
        projectP2.SUBS_DONE.push(pb.subscriptionID);
        emit OpenedPack(
            pbr.projectID,
            pbr.packSoldID,
            pb.wonItems,
            pb.openedBy
        );
    }

    function getUnspentLinkBalance(uint256 projectID)
        public
        view
        returns (uint96 availableBalance, uint64[] memory subscriptionIDs)
    {
        ProjectsP2 storage projectP2 = projectsP2[projectID];
        uint96 linkToRedeem = 0;
        for (uint16 i = 0; i < projectP2.SUBS_DONE.length; i++) {
            uint64 subscriptionID = projectP2.SUBS_DONE[i];
            (uint96 bal, , , ) = COORDINATOR.getSubscription(subscriptionID);
            linkToRedeem += bal;
        }
        return (linkToRedeem, projectP2.SUBS_DONE);
    }

    function withdrawUnspentLink(uint256 projectID) public {
        isValidCaller(projectID);
        uint256 linkToRedeem = 0;
        ProjectsP2 storage projectp2 = projectsP2[projectID];
        for (uint256 i = 0; i < projectp2.SUBS_DONE.length; i++) {
            uint64 subscriptionID = projectp2.SUBS_DONE[i];
            (uint96 bal, , , ) = COORDINATOR.getSubscription(subscriptionID);
            COORDINATOR.cancelSubscription(subscriptionID, address(this));
            linkToRedeem += bal;
        }
        delete projectp2.SUBS_DONE;
        LinkTokenInterface(chainlinkTokenAddress()).transfer(
            msg.sender,
            linkToRedeem
        );
    }

    function generateWinnings(
        uint256 projectid,
        uint256[] memory randomness,
        uint256 requestid
    ) private {
        isValidProject(projectid);
        Projects storage project = projects[projectid];
        for (uint256 i = 0; i < project.amountToPayOutPerPack; i++) {
            // expandedValues[i] = uint256(keccak256(abi.encode(randomness, i)));
            uint256 _randomResult = randomness[i] % project.items.length;
            removeItemFromWinnings(projectid, _randomResult, requestid);
        }
    }

    function createToken(
        string memory _uriforcollection,
        uint32 amountToPayOutPerPack,
        uint256[] calldata ids,
        string calldata collectionname,
        string calldata collectionsymbol,
        address customContract,
        bool isJson
    ) public payable returns (uint256 projectCreated) {
        MinterInterface minter = MinterInterface(minterAddress);
        require(ids.length % amountToPayOutPerPack == 0, "1"); //not divisible
        require(amountToPayOutPerPack <= MAX_ITEMS_PER_PACK, "2"); //tomanyitems
        require(
            ids.length / amountToPayOutPerPack <= MAX_PACKS,
            "3" //tomanypacks
        );
        require(LAUNCH_ENABLED, "4"); //launches_not_enabled

        uint256 index = projectAmount;
        Projects storage project = projects[index];
        ProjectsP2 storage projects2 = projectsP2[index];
        packCreators[tx.origin].push(index);
        projects2.isJson = isJson;
        project.owner = tx.origin;
        project.items = ids;
        project.id = index;
        project.amountToPayOutPerPack = amountToPayOutPerPack;
        project.packsForSale = ids.length / amountToPayOutPerPack;
        projects2.name = collectionname;
        projects2.enabled = true;
        string memory tmpColUri = _uriforcollection;
        if (ids[0] == 0) {
            project.have0ItemID = true;
        }
        if (customContract != address(0)) {
            require(cce[customContract], "5"); //invalid_custom_contract
            project.contractAddress = customContract;
        } else {
            project.contractAddress = minter.mintNFT(
                tmpColUri,
                owner,
                address(this),
                projects2.name,
                collectionsymbol,
                msg.sender,
                projects2.isJson
            );
        }
        //  event ProjectCreated(
        emit ProjectCreated(
            index, //projectid
            tx.origin, //creator
            project.contractAddress, //collection address
            project.items, //collection id's
            project.amountToPayOutPerPack, //amount to pay out per pack
            project.packsForSale, //packs for sale
            projects2.name
        );
        projectAmount++;
        return index;
    }

    function createTokenPart2(
        uint256 projectId,
        uint256 borderId,
        string calldata packBackgroundImageUrl,
        uint256 pricePerPack,
        uint256 launchTime,
        uint256[] calldata paymentMethods_,
        uint256 basePayment,
        uint256 slippage,
        uint16 gasLane
    ) public payable {
        PackHelperInterface packBorders = PackHelperInterface(
            packBordersAddress
        );
        Projects storage project = projects[projectId];
        ProjectsP2 storage projects2 = projectsP2[projectId];

        isValidProject(projectId);
        isValidCaller(projectId);
        require(msg.value >= PACK_LAUNCH_COST, "1"); //not Enough funds
        require(Payments.getGasLane(gasLane) != 0x0, "2"); //invalid gas lane

        project.pricePerPack = pricePerPack;
        projects2.launchTime = launchTime;
        projects2.GAS_LANE = gasLane;

        uint256 pid = projectId;
        uint256 bid = borderId;
        string memory pbg = packBackgroundImageUrl;
        uint256[] calldata paymentMethods2 = paymentMethods_;
        uint256 bp = basePayment;
        packBorders.useBorder(bid);
        MinterInterface minter = MinterInterface(minterAddress);
        project.packAddress = minter.mintPacks(
            pid,
            projects2.name,
            string(
                abi.encodePacked(
                    "SeaPad ProjectID: #",
                    SeapadHelper.uint2str(pid)
                )
            ),
            msg.sender,
            owner
        );
        // validPackAddress[project.packAddress] = true;
        uint256 slippage2 = slippage;
        Payments.insertNewProject{value: msg.value}(
            msg.sender,
            pid,
            paymentMethods2,
            bp,
            slippage2
        );
        address tmpPackAddress = project.packAddress;
        projects2.BASE_FEE_PERCENTAGE = PACK_SALE_BASE_FEE_PERCENTAGE;
        makeChainLinkRequest(
            project.amountToPayOutPerPack,
            projects2.name,
            project.packsForSale,
            pid,
            bid,
            pbg,
            SeapadHelper.toAsciiString(tmpPackAddress)
        );
        bool _isJson = projects2.isJson;
        uint256 ppp = project.pricePerPack;
        uint256 lt = projects2.launchTime;
        emit ProjectCreatedP2(pid, bid, pbg, ppp, lt, _isJson, tmpPackAddress);
    }

    function makeChainLinkRequest(
        uint32 amountToPayOutPerPack,
        string memory projectName,
        uint256 totalPacks,
        uint256 projectId,
        uint256 borderId,
        string memory packBackgroundImageUrl,
        string memory packAddress
    ) private returns (bytes32 requestID) {
        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillMultipleParameters.selector
        );
        request.add(
            "itemsPerPack",
            SeapadHelper.uint2str(amountToPayOutPerPack)
        );
        request.add("projectName", projectName);
        request.add("totalPacks", SeapadHelper.uint2str(totalPacks));
        request.add("projectId", SeapadHelper.uint2str(projectId));
        request.add("borderId", SeapadHelper.uint2str(borderId));
        request.add("packBackgroundUrl", packBackgroundImageUrl);
        request.add("packAddress", packAddress);
        return sendOperatorRequest(request, CHAINLINK_FEE_PACK_GENERATION);
    }

    function getMyWhitelistStatus(uint256 projectID, address _address)
        public
        view
        returns (bool)
    {
        Projects storage project = projects[projectID];
        return project.whitelist[_address];
    }

    function isValidProject(uint256 index)
        private
        view
        returns (bool validProject)
    {
        require(
            projects[index].contractAddress != address(0),
            "IP" //INVALID PROJECT
        );
        return true;
    }

    function isValidCaller(uint256 projectrid)
        private
        view
        returns (bool validProject)
    {
        require(
            projects[projectrid].owner == tx.origin || tx.origin == owner,
            "IO" //INVALID OWNER
        );
        return true;
    }

    function withdrawTokens(uint256 amt, address tokenAddress)
        public
        onlyOwner
    {
        IERC20 t = IERC20(tokenAddress);
        t.transfer(owner, amt);
    }

    function withdrawEth(uint256 amt) public onlyOwner {
        payable(msg.sender).transfer(amt);
    }

    //approveCustomContract
    // function ACC(address cc, bool valid) public onlyOwner {
    //     cce[cc] = valid;
    // }
    function adminAddProjectUri(
        string calldata _unopenedUri,
        string calldata _openedUri,
        uint256 projectId
    ) public onlyOwner {
        // adminProjectUris.push(uri);
        ProjectsP2 storage _projectsP2 = projectsP2[projectId];
        _projectsP2.unopenedUri = _unopenedUri;
        _projectsP2.openedUri = _openedUri;
    }

    function fulfillMultipleParameters(
        bytes32 requestId,
        string calldata _unopenedUri,
        string calldata _openedUri,
        uint256 projectId
    ) public recordChainlinkFulfillment(requestId) {
        isValidProject(projectId);
        ProjectsP2 storage _projectsP2 = projectsP2[projectId];
        _projectsP2.unopenedUri = _unopenedUri;
        _projectsP2.openedUri = _openedUri;
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

    address public seapadAddress;
    address public seapadOwner;
    address public packCollectionOwner;

    uint256 private projectid;
    bool public opened = false;
    string private baseExtension = ".json";
    string pendingUri = "https://cdn.seapad.io/pending.json";
    string storefrontURI = "https://cdn.seapad.io/storefront.json";
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

    uint256 public amountSeapadWithdrawable = 0;
    uint256 public amountOwnerWithdrawable = 0;
    uint256 public seapadRoyaltyPercentage = 5000; //default 50% goes to seapad, can add 2 commas.

    receive() external payable {
        //calculate 19% to seapad and rest to owner in solidity
        uint256 seapadAmount = (msg.value * seapadRoyaltyPercentage) / 10000;
        uint256 ownerAmount = msg.value - seapadAmount;
        amountSeapadWithdrawable += seapadAmount;
        amountOwnerWithdrawable += ownerAmount;
    }

    modifier onlySeapad() {
        _;
        require(
            msg.sender == seapadAddress || msg.sender == seapadOwner,
            "Only seapadAddress contract can call this (Pack.sol)."
        );
    }

    modifier onlyCollectionOwner() {
        _;
        require(
            msg.sender == packCollectionOwner,
            "Only contract owner can call this (Pack.sol)."
        );
    }

    function withdrawSeapad() public onlySeapad {
        uint256 amount = amountSeapadWithdrawable;
        amountSeapadWithdrawable = 0;
        payable(seapadAddress).transfer(amount);
    }

    function withdrawOwner() public onlyCollectionOwner {
        uint256 amount = amountOwnerWithdrawable;
        amountOwnerWithdrawable = 0;
        payable(packCollectionOwner).transfer(amount);
    }

    function updateRoyaltyPercentage(uint256 newPercentage) public onlySeapad {
        seapadRoyaltyPercentage = newPercentage;
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
        Parent.PacksBought memory pack = Parent(seapadAddress).getPacksSold(
            projectid,
            tokenId
        );
        //if openRequested then packs are not transfarabele, only if to is the dead wallet
        //if minted packs are not transfarebble
        if (pack.requestid != bytes32(0)) {
            require(to == address(0), "Pack is open, cannot transfer");
        }

        Parent p = Parent(seapadAddress);
        p.updatePackOwner(projectid, tokenId, to, from);
    }

    constructor(
        // string memory thisUri,
        // string memory uriOpened,
        address _packCollectionOwner,
        address _seapadAddress,
        address _seapadOwner,
        uint256 _projectid,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        seapadAddress = _seapadAddress;
        packCollectionOwner = _packCollectionOwner;
        seapadOwner = _seapadOwner;
        projectid = _projectid;
        transferOwnership(_seapadAddress);
        // _uri = thisUri;
        // _uriOpened = uriOpened;
    }

    function packRecievedImages() public view returns (bool recieved) {
        Parent parentContract = Parent(seapadAddress);
        return parentContract.packRecievedImages(projectid);
    }

    function burnPack(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender ||
                msg.sender == seapadAddress ||
                msg.sender == owner(),
            "you cant burn this pack"
        );
        _burn(tokenId);
    }

    function packOpened(uint256 packid) public view returns (bool) {
        Parent parentContract = Parent(seapadAddress);
        Parent.PacksBought memory pack = parentContract.getPacksSold(
            projectid,
            packid
        );
        return pack.minted;
    }

    function openPack(uint256 packid) public {
        Parent parentContract = Parent(seapadAddress);
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
        Parent parentContract = Parent(seapadAddress);
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

    function updateParentContract(address _seapadAddress, address _seapadOwner)
        public
        onlySeapad
    {
        seapadAddress = _seapadAddress;
        seapadOwner = _seapadOwner;
    }

    function contractURI() public view returns (string memory) {
        return storefrontURI;
    }

    function mintNewToken(address owner, uint256 idToMint) public onlySeapad {
        _mint(owner, idToMint);
    }
}

// contracts/BoosterEnabledToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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
    address public seapadOwner;
    address public seapadAddress;
    string public storefronturl;
    bool public isJson = false;
    string __uri;
    uint256[] freeMintIds;
    modifier onlySeapad() {
        _;
        require(
            msg.sender == seapadOwner || msg.sender == seapadAddress,
            "Only SeaPad parent/owner can call this (NFT.sol)"
        );
    }

    function updateSeapadAddress(address seapadOwner_, address seapadAddress_)
        public
        onlySeapad
    {
        seapadOwner = seapadOwner_;
        seapadAddress = seapadAddress_;
    }

    constructor(
        string memory thisUri,
        address _seapadOwner,
        address _seapadAddress,
        string memory _name,
        string memory _symbol,
        address collectionOwner,
        bool _isJson
    ) ERC721(_name, _symbol) {
        // projectid = _projectid;
        seapadOwner = _seapadOwner;
        seapadAddress = _seapadAddress;
        __uri = thisUri;
        isJson = _isJson;
        transferOwnership(collectionOwner);
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
    function mintNewToken(address owner, uint256 idToMint)
        public
        onlySeapad
        returns (bool)
    {
        _mint(owner, idToMint);
        return true;
    }

    //withdraw tokens
    function withdrawTokens(address to, address tokenAddress) public onlyOwner {
        require(
            msg.sender == owner(),
            "Only owner can withdraw tokens (NFT.sol)"
        );
        IERC20 token = IERC20(tokenAddress);
        token.transfer(to, token.balanceOf(address(this)));
    }

    //withdraw eth
    function withdrawETH(uint256 amount) public onlyOwner {
        require(msg.sender == owner(), "Only owner can withdraw ETH (NFT.sol)");
        // address payable owner = owner();
        payable(msg.sender).transfer(amount);
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
        string calldata symbol,
        address _packCollectionOwner,
        address _seapadOwner
    ) public onlyParentContact returns (address packAddress) {
        Pack packs = new Pack(
            _packCollectionOwner,
            parent,
            _seapadOwner,
            projectid,
            name,
            symbol
        );
        // string memory thisUri, string memory uriOpened, address _parent, uint _projectid, string memory _name, string memory _symbol
        return address(packs);
    }

    function mintNFT(
        string memory _uri,
        address _seapadOwner,
        address _seapadAddress,
        string memory _name,
        string memory _symbol,
        address collectionOwner,
        bool isJson
    ) public onlyParentContact returns (address nftAddres) {
        NFT token = new NFT(
            _uri,
            _seapadOwner,
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256**(32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint256 mask = (256**len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
          mstore(bufptr, add(off, len))
        }
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = (256**len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);

  function isAuthorizedSender(address node) external view returns (bool);

  function withdraw(address recipient, uint256 amount) external;

  function withdrawable() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OracleInterface.sol";
import "./ChainlinkRequestInterface.sol";

interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  ) external returns (bool);

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function distributeFunds(address payable[] calldata receivers, uint256[] calldata amounts) external payable;

  function getAuthorizedSenders() external returns (address[] memory);

  function setAuthorizedSenders(address[] calldata senders) external;

  function getForwarder() external returns (address);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ENSInterface {
  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(bytes32 node, address resolver) external;

  function setOwner(bytes32 node, address owner) external;

  function setTTL(bytes32 node, uint64 ttl) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);

  function ttl(bytes32 node) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import {ENSResolver as ENSResolver_Chainlink} from "./vendor/ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
abstract contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 internal constant LINK_DIVISIBILITY = 10**18;
  uint256 private constant AMOUNT_OVERRIDE = 0;
  address private constant SENDER_OVERRIDE = address(0);
  uint256 private constant ORACLE_ARGS_VERSION = 1;
  uint256 private constant OPERATOR_ARGS_VERSION = 2;
  bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
  address private constant LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private s_ens;
  bytes32 private s_ensNode;
  LinkTokenInterface private s_link;
  OperatorInterface private s_oracle;
  uint256 private s_requestCount = 1;
  mapping(bytes32 => address) private s_pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddr address to operate the callback on
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddr,
    bytes4 callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddr, callbackFunctionSignature);
  }

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildOperatorRequest(bytes32 specId, bytes4 callbackFunctionSignature)
    internal
    view
    returns (Chainlink.Request memory)
  {
    Chainlink.Request memory req;
    return req.initialize(specId, address(this), callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendChainlinkRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      ChainlinkRequestInterface.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      address(this),
      req.callbackFunctionId,
      nonce,
      ORACLE_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `sendOperatorRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendOperatorRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      OperatorInterface.operatorRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackFunctionId,
      nonce,
      OPERATOR_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param nonce used to generate the request ID
   * @param payment The amount of LINK to send for the request
   * @param encodedRequest data encoded for request type specific format
   * @return requestId The request ID
   */
  function _rawRequest(
    address oracleAddress,
    uint256 nonce,
    uint256 payment,
    bytes memory encodedRequest
  ) private returns (bytes32 requestId) {
    requestId = keccak256(abi.encodePacked(this, nonce));
    s_pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    require(s_link.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) internal {
    OperatorInterface requested = OperatorInterface(s_pendingRequests[requestId]);
    delete s_pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice the next request count to be used in generating a nonce
   * @dev starts at 1 in order to ensure consistent gas cost
   * @return returns the next request count to be used in a nonce
   */
  function getNextRequestCount() internal view returns (uint256) {
    return s_requestCount;
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(address oracleAddress) internal {
    s_oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(address linkAddress) internal {
    s_link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress() internal view returns (address) {
    return address(s_link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(address ensAddress, bytes32 node) internal {
    s_ens = ENSInterface(ensAddress);
    s_ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 requestId)
    internal
    recordChainlinkFulfillment(requestId)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
    delete s_pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    require(s_pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORChainlink} from "./vendor/CBORChainlink.sol";
import {BufferChainlink} from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory data) internal pure {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}