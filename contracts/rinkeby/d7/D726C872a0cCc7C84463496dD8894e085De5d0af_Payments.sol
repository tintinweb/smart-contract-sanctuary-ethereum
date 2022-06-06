// contracts/BoosterEnabledToken.sol
// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;

pragma solidity ^0.8.1;

import "./Minter.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

// import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
// import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

interface IUniswapV2Router02 {
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

interface CollectionInterface {
    // BatchMint
}

interface WethInterface {
    function withdraw(uint256) external;

    function deposit() external payable;
}

contract Payments is Ownable {
    address public chainLinkToken;
    uint256 public chainLinkFee; //1 LINK
    address public parentAddress;
    uint256 public ethEarned = 0;
    modifier onlyParentContract() {
        _;
        require(
            msg.sender == parentAddress || msg.sender == owner(),
            "Only parent contract can call this (Minter.sol)."
        );
    }
    IUniswapV2Router02 private immutable uniswapV2Router;
    IUniswapV2Router02 _uniswapV2Router;

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
    mapping(uint256 => PaymentMethods) private paymentMethods;

    constructor(
        address parentAddress_,
        address _chainlinkToken,
        address _routerAddress,
        uint256 _chainLinkFee
    ) {
        // address routerAddress = _routerAddress;
        _uniswapV2Router = IUniswapV2Router02(_routerAddress);
        //https://pancake.kiemtienonline360.com/#/swap = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 (Works for binance testnet);
        // 0x10ED43C718714eb63d5aA57B78B54704E256024E pancakeswap livenet
        // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ropsten,kovan testnet and eth mainnet uniswap
        // 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506 avax sushiswap
        chainLinkToken = _chainlinkToken;
        chainLinkFee = _chainLinkFee;

        parentAddress = address(parentAddress_);
        uniswapV2Router = _uniswapV2Router;
    }

    function updateParentContract(address newParentContract) public onlyOwner {
        parentAddress = newParentContract;
    }

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
            chainLinkFee
        )[0];
        //slippage to eth amt.
        uint256 MINETHNEEDEDWITHSLIPPAGE = ((MINETHNEEDED * slippage) / 10000) +
            MINETHNEEDED;
        require(
            msg.value >= MINETHNEEDEDWITHSLIPPAGE,
            "need more eth to do transfer."
        );
        // function buyTokensWithETH2(uint256 amountEthToSend, uint256 minTokenAmountToRecieve, address tokenAddressToRecieve)
        uint256 balEfter = buyTokensWithETH2(
            MINETHNEEDEDWITHSLIPPAGE,
            chainLinkFee,
            chainLinkToken,
            msg.value
        );
        require(validBasePayment, "Base payment method is not valid1.");
        require(
            IERC20(chainLinkToken).balanceOf(address(this)) >= chainLinkFee,
            "Could not get enough chainlink!"
        );
        // IERC20(chainLinkToken).approve(parentAddress, chainLinkFee);
        IERC20(chainLinkToken).transfer(parentAddress, chainLinkFee);

        // buyLinkToken(address tokenToConvertFrom, uint256 fullPaymentAmount, uint256 amountToTokenToBuy, address linkTokenAddress, uint slippage);
        projects[projectId].basePayment = basePayment;
        projects[projectId].paymentMethods = paymentMethods_;

        // projects[projectId].paymetnMethods = paymentMethods_;
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

    // uint256 public ethrecieved;
    function swap1Token2AnotherThroughETH2(
        address tokensToSwapToMainToken,
        uint256 amountToSwap,
        uint256 slippage,
        address finalCurrencyToRecieve
    ) public payable returns (uint256) {
        IERC20 tokenToSwap = IERC20(tokensToSwapToMainToken);
        //to get the real amount to swap we first need to see, how much it would cost us to get the final amount.
        //

        require(
            tokenToSwap.transferFrom(msg.sender, address(this), amountToSwap),
            "token transferFrom failed."
        );
        require(
            tokenToSwap.approve(address(uniswapV2Router), amountToSwap),
            "approve failed."
        );
        uint256 MIN_RECIEVE_AMT_ETH = getEstimatedETHforToken(
            tokensToSwapToMainToken,
            amountToSwap
        )[0];
        uint256 slippageAmount = (MIN_RECIEVE_AMT_ETH * slippage) / 10000;
        uint256 balBeforeEth = address(this).balance;
        _uniswapV2Router.swapExactTokensForETH(
            amountToSwap,
            MIN_RECIEVE_AMT_ETH - slippageAmount,
            getPathToEth(tokensToSwapToMainToken),
            address(this),
            block.timestamp + 150
        );
        uint256 ethrecieved = address(this).balance - balBeforeEth;
        buyTokensWithETH(ethrecieved, finalCurrencyToRecieve, slippage);
        return ethrecieved;
    }

    //recieve token , and send remaining back.
    function buyTokensWithETH2(
        uint256 amountEthToSend,
        uint256 minTokenAmountToRecieve,
        address tokenAddressToRecieve,
        uint256 totalEthAmt
    ) public returns (uint256) {
        // uint256 ETH_TO_SPEND = getEstimatedETHforToken(minTokenAmountToRecieve, amountEthToSend)[0];
        _uniswapV2Router.swapExactETHForTokens{value: amountEthToSend}(
            minTokenAmountToRecieve,
            getPathForToken(tokenAddressToRecieve),
            address(this), //goes back to parent contract.
            block.timestamp + 150
        );
        uint256 balEfter = totalEthAmt - amountEthToSend;
        // address payable sender = parmentAddress;
        // payable(parentAddress).transfer(balEfter);
        return balEfter;
    }

    function buyTokensWithETH(
        uint256 amountEthToSend,
        address tokensToRecieve,
        uint256 slippage
    ) public {
        uint256 slippageAmount = (amountEthToSend * slippage) / 10000;
        uint256 MIN_RECIEVE_AMT_SECOND_CURRENCY = getEstimatedTokenRecieveForEth(
                tokensToRecieve,
                amountEthToSend
            )[1];
        _uniswapV2Router.swapExactETHForTokens{value: amountEthToSend}(
            MIN_RECIEVE_AMT_SECOND_CURRENCY - slippageAmount,
            getPathForToken(tokensToRecieve),
            msg.sender,
            block.timestamp + 60
        );
    }

    //THIS BUYS ETH, NOT WETH
    function buyEthWithToken(
        uint256 tokenAmountToSpend,
        address tokenAddress,
        uint256 estimatedEthToRecieve
    ) public returns (uint256 ETHRecieved) {
        // IERC20 token = IERC20(uniswapV2Router.WETH());
        IERC20(tokenAddress).approve(
            address(uniswapV2Router),
            tokenAmountToSpend
        );
        // uint256 estimatedToRecieveMinimum = getEstimatedETHRecievedForToken(tokenAddress, tokenAmountToSpend)[0];
        uint256 prevBal = address(this).balance;
        _uniswapV2Router.swapExactTokensForETH(
            tokenAmountToSpend,
            estimatedEthToRecieve,
            getPathToEth(tokenAddress),
            address(this),
            block.timestamp + 150
        );
        uint256 afterBal = address(this).balance;
        uint256 recievedAmt = afterBal - prevBal;
        return recievedAmt;
    }

    function buyLinkToken(
        address tokenToConvertFrom,
        uint256 fullPaymentAmount,
        uint256 amountToTokenToBuy,
        address linkTokenAddress,
        uint256 slippage
    ) public payable onlyParentContract returns (uint256) {
        IERC20 token = IERC20(tokenToConvertFrom);
        // IERC20 tokenRecieved = IERC20(tokenToConvertFrom);
        // uint256 balanceBeforeToken = token.balanceOf(address(this)); // 29996195677161989"
        address tokenToConvertFrom_ = tokenToConvertFrom;
        //how much does this contract have after we recieved.
        // get estimated price it would cost us to buy chainlink token.
        uint256 slippage2 = (amountToTokenToBuy * slippage) / 10000;
        uint256 estimated = getEstimatedETHforToken(
            linkTokenAddress,
            amountToTokenToBuy + slippage2
        )[0];

        //if this payment is made with WETH, we only need to purchase chainlink tokens.
        if (tokenToConvertFrom_ == address(uniswapV2Router.WETH())) {
            //this is weth payment.
            require(
                fullPaymentAmount >= estimated,
                "not enough eth to buy tokens."
            );
            require(
                token.transferFrom(
                    msg.sender,
                    address(this),
                    fullPaymentAmount
                ),
                "token transferFrom failed."
            );

            _uniswapV2Router.swapExactETHForTokens{value: estimated}(
                amountToTokenToBuy,
                getPathForToken(linkTokenAddress),
                address(this),
                block.timestamp + 150
            ); // spend 10

            //transfer remainding eth to parent contract.
            uint256 ethRemaining = fullPaymentAmount - estimated;
            require(
                token.transferFrom(address(this), msg.sender, ethRemaining),
                "token transferFrom failed."
            );
            //transfer link token to parent contract.
            IERC20(linkTokenAddress).transfer(
                parentAddress,
                amountToTokenToBuy
            );
            return estimated;
        } else {
            //if it is not eth, we first swap to eth and then to chainlink token from that eth,
            require(
                token.transferFrom(
                    msg.sender,
                    address(this),
                    fullPaymentAmount
                ),
                "token transferFrom failed."
            );

            uint256 tokensNeededForETHAmt = getEstimatedTokenForETH(
                tokenToConvertFrom,
                estimated
            )[0]; //amount of paymentMethodToken needed to get the eth.
            //
            string memory errorMessage = string(
                abi.encodePacked(
                    "Payment needs at least least: ",
                    uint2str(tokensNeededForETHAmt),
                    " tokens to buy eth!"
                )
            );
            require(fullPaymentAmount >= tokensNeededForETHAmt, errorMessage);

            IERC20(tokenToConvertFrom).approve(
                address(uniswapV2Router),
                tokensNeededForETHAmt
            );
            // buyEthWithToken(tokensNeededForETHAmt, tokenToConvertFrom, (estimated - slippage2));
            uint256 balBefore = address(this).balance;
            // approve uniswap
            _uniswapV2Router.swapExactTokensForETH(
                tokensNeededForETHAmt,
                estimated,
                getPathToEth(address(tokenToConvertFrom_)),
                address(this),
                block.timestamp + 150
            );
            balBefore = address(this).balance - balBefore;
            _uniswapV2Router.swapExactETHForTokens{value: balBefore}(
                amountToTokenToBuy,
                getPathForToken(linkTokenAddress),
                address(this),
                block.timestamp + 150
            );
            IERC20(linkTokenAddress).transfer(
                parentAddress,
                amountToTokenToBuy
            ); //transfer link token to parent contract.

            uint256 balanceAfterToken = fullPaymentAmount -
                tokensNeededForETHAmt;
            IERC20(tokenToConvertFrom).transfer(
                parentAddress,
                balanceAfterToken
            );
            return tokensNeededForETHAmt; //how much of the users tokens we spent in total to get the chainlink token (with slippage).
        }
    }

    // function

    // GetAmountsIn()
    //GetAmountsIn() will return how much TOKENA you would need to recieve given amount TOKENB .
    //GetAmountOut() will return how much TOKENB you would get for a given TOKENA.

    function getEstimatedTokenNeededToRecieveOtherToken(
        address inputToken,
        address outputToken,
        uint256 outputTokensAmountToGetPriceFor
    ) public view returns (uint256[] memory) {
        return
            uniswapV2Router.getAmountsIn(
                outputTokensAmountToGetPriceFor,
                getPathToTokenFromToken(inputToken, outputToken)
            );
    }

    // GetAmountOut() will return how much ETH you would get for a given TOKEN.
    function getEstimatedETHRecievedForToken(address token, uint256 tokenAmount)
        public
        view
        returns (uint256[] memory)
    {
        return uniswapV2Router.getAmountsOut(tokenAmount, getPathToEth(token));
    }

    // you call this function to get figure out how much TOKEN you would need to get wETH amount.
    function getEstimatedTokenForETH(
        address token,
        uint256 amountOfETHToConvert
    ) public view returns (uint256[] memory) {
        return
            uniswapV2Router.getAmountsIn(
                amountOfETHToConvert,
                getPathToEth(token)
            );
    }

    function getEstimatedETHforToken(
        address token,
        uint256 amountOfTokensToRecieve
    ) public view returns (uint256[] memory) {
        return
            uniswapV2Router.getAmountsIn(
                amountOfTokensToRecieve,
                getPathForToken(token)
            );
    }

    function getEstimatedTokenRecieveForEth(
        address token,
        uint256 amountOfTokensToRecieve
    ) public view returns (uint256[] memory) {
        return
            uniswapV2Router.getAmountsOut(
                amountOfTokensToRecieve,
                getPathForToken(token)
            );
    }

    function getPathToTokenFromToken(address inputToken, address outputToken)
        private
        pure
        returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = inputToken;
        path[1] = outputToken;
        return path;
    }

    function getPathToEth(address token)
        private
        view
        returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = uniswapV2Router.WETH();
        return path;
    }

    function getPathForToken(address token)
        private
        view
        returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(token);
        return path;
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

    function updateParent(address newParent) public onlyOwner {
        parentAddress = newParent;
        // minterAddress = newMinterAddress;
        // packBordersAddress = newPackBorderAddress;
    }

    function uint2str(uint256 _i)
        internal
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
}

// contracts/BoosterEnabledToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol";

interface Parent {
    function openPack(uint256 projectid, uint256 packSoldID_)
        external
        returns (uint256[] calldata wonItems);

    function getPacksSold(uint256 projectid, uint256 packSoldID_)
        external
        view
        returns (
            uint256 randomness,
            uint256 projectId,
            address purchasedBy,
            uint256[] memory wonItems,
            bytes32 requestid,
            bool minted
        );

    function updatePackOwner(
        uint256 projectid,
        uint256 packSoldID_,
        address newOwner
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
        (, , , , bytes32 requestid, bool minted ) = Parent(parent).getPacksSold(
            projectid,
            tokenId
        );
        //if openRequested then packs are not transfarabele, only if to is the dead wallet
        //if minted packs are not transfarebble
        if(requestid != bytes32(0)) {
            require(to == address(0), "Pack is open, cannot transfer");
        }


        Parent p = Parent(parent);
        p.updatePackOwner(projectid, tokenId, to);
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
        (, , , , , bool minted) = parentContract.getPacksSold(
            projectid,
            packid
        );
        return minted;
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