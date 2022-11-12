// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";
import "https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol";
import "https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol";

//            _ _              __  __      _
//      /\   | (_)            |  \/  |    | |
//     /  \  | |_  ___ _ __   | \  / | ___| |_ __ _
//    / /\ \ | | |/ _ \ '_ \  | |\/| |/ _ \ __/ _` |
//   / ____ \| | |  __/ | | | | |  | |  __/ || (_| |
//  /_/    \_\_|_|\___|_| |_| |_|  |_|\___|\__\__,_|

// AlienMeta.wtf - Mowgli + Dev Lrrr

contract SeggzCoin is ERC20, Pausable, Ownable {
    uint256 private immutable oneOneHundredThousandth = 100000;
    uint256 public MaxWalletPCT = 5;

    function viewMaxWalletSEGGZ() external view returns (uint256) {
        uint256 totalS = totalSupply();
        uint256 MaxSeggzPerWallet = (totalS * MaxWalletPCT) /
            oneOneHundredThousandth;
        return MaxSeggzPerWallet;
    }

    function modifyMaxWalletPCT(uint256 _newValue) external onlyOwner {
        require(_newValue <= oneOneHundredThousandth, "not allowed");
        MaxWalletPCT = _newValue;
    }

    bool public isCEX = false;

    function changeIsCEX() external onlyOwner {
        isCEX = !isCEX;
    }

    bool public takeBuyTax = true;
    bool public takeSellTax = true;

    function ModifyTakeBuyTax() external onlyOwner {
        takeBuyTax = !takeBuyTax;
    }

    function ModifyTakeSellTax() external onlyOwner {
        takeSellTax = !takeSellTax;
    }

    bool public pauseBuy = false;
    bool public pauseSell = false;

    function ModifyPauseBuy() external onlyOwner {
        pauseBuy = !pauseBuy;
    }

    function ModifyPauseSell() external onlyOwner {
        pauseSell = !pauseSell;
    }

    function buyIsNotPaused() public view returns (bool) {
        if (pauseBuy) {
            return false;
        }
        return true;
    }

    function sellIsNotPaused() public view returns (bool) {
        if (pauseSell) {
            return false;
        }
        return true;
    }

    uint256 public maxBuyInSEGGZ = 50000;

    function modifyMaxBuyInSEGGZ(uint256 _newValue) external onlyOwner {
        maxBuyInSEGGZ = _newValue;
    }

    uint256 public maxSellInSEGGZ = 0;

    function modifyMaxSellInSEGGZ(uint256 _newValue) external onlyOwner {
        maxSellInSEGGZ = _newValue;
    }

    function checkTransferIsNotMoreThanMaxSEGGZAllowed(
        uint256 _amount,
        bool _isSell,
        address _reciever
    ) public view returns (bool) {
        if (liquidityProvider[_reciever]) {
            return true;
        }
        if (_isSell) {
            if (maxSellInSEGGZ == 0) {
                return true;
            }
            if (_amount > (maxSellInSEGGZ * 10**18)) {
                return false;
            }
            return true;
        } else {
            if (maxBuyInSEGGZ == 0) {
                return true;
            }
            if (_amount > (maxBuyInSEGGZ * 10**18)) {
                return false;
            }
            return true;
        }
    }

    uint256 private immutable maxTaxValue = 500;

    uint256 public nftHolderReduction = 50;
    uint256 public maxSupply = 21000000000;
    uint256 public taxBalance;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    IERC721 public spaceEggzNFT;

    mapping(address => bool) public isExlueded;

    struct Tokenomics {
        string name;
        address wallet;
        uint256 buyTaxValue;
        uint256 sellTaxValue;
        bool isValid;
    }
    Tokenomics[] public tokenomics;

    constructor() ERC20("SEGGZCoin", "SEGGZ") {
        address spaceEggzNFTA = 0x839F1b77ABaeE9116CEf7e77385b2E02e7871fe3;
        _mint(address(this), maxSupply * 10**18);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        spaceEggzNFT = IERC721(spaceEggzNFTA);
        isExlueded[address(this)] = true;
        isExlueded[uniswapV2Pair] = true;
        isExlueded[address(uniswapV2Router)] = true;
    }

    function updateSpaceEggzNFTContractAddress(address _spaceEggzNFT)
        external
        onlyOwner
    {
        spaceEggzNFT = IERC721(_spaceEggzNFT);
    }

    receive() external payable {}

    mapping(address => bool) public liquidityProvider;

    function addliquidityProviderWallet(address _user) private onlyOwner {
        liquidityProvider[_user] = true;
    }

    function addExludedMember(address _user) public onlyOwner {
        isExlueded[_user] = true;
    }

    function removeExludedMember(address _user) external onlyOwner {
        isExlueded[_user] = false;
    }

    function calculateMaxTokensPerWallet()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 totalS = totalSupply();
        uint256 maxQtePerWallet = (totalS * MaxWalletPCT) /
            oneOneHundredThousandth;
        return (totalS, MaxWalletPCT, maxQtePerWallet);
    }

    function modifyNftHolderReduction(uint256 _newValue) external onlyOwner {
        nftHolderReduction = _newValue;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getTaxValueFromTokenomics()
        public
        view
        returns (uint256, uint256)
    {
        uint256 totalSellTax = 0;
        uint256 totalBuytTax = 0;
        for (uint256 i = 0; i < tokenomics.length; i++) {
            Tokenomics memory _tokenomics = tokenomics[i];
            if (_tokenomics.isValid) {
                totalBuytTax += _tokenomics.buyTaxValue;
                totalSellTax += _tokenomics.sellTaxValue;
            }
        }
        return (totalBuytTax, totalSellTax);
    }

    function addTokenmic(
        string memory _name,
        uint256 _sellTaxValue,
        uint256 _buyTaxValue,
        address _wallet,
        bool _isValid
    ) external onlyOwner {
        Tokenomics memory _tokenomics;
        _tokenomics.isValid = _isValid;
        _tokenomics.wallet = _wallet;
        _tokenomics.name = _name;
        _tokenomics.buyTaxValue = _sellTaxValue;
        _tokenomics.sellTaxValue = _buyTaxValue;

        tokenomics.push(_tokenomics);
    }

    function modifyTokenomic(
        string memory _name,
        uint256 index,
        uint256 _sellTaxValue,
        uint256 _buyTaxValue,
        address _wallet,
        bool _isValid
    ) external onlyOwner {
        Tokenomics memory _tokenomics = tokenomics[index];
        _tokenomics.isValid = _isValid;
        _tokenomics.wallet = _wallet;
        _tokenomics.name = _name;
        _tokenomics.buyTaxValue = _sellTaxValue;
        _tokenomics.sellTaxValue = _buyTaxValue;
        tokenomics[index] = _tokenomics;
    }

    function percentageCalculator(uint256 x, uint256 balance)
        public
        view
        returns (uint256)
    {
        (
            uint256 buy_tax_value,
            uint256 sell_tax_value
        ) = getTaxValueFromTokenomics();
        uint256 totalTax = buy_tax_value + sell_tax_value;
        uint256 contractBalance = balance;

        uint256 total = (x * contractBalance) / totalTax;
        return total;
    }

    function showPCTThisWalletHolds(address _user)
        public
        view
        returns (uint256)
    {
        uint256 totalS = totalSupply();
        uint256 holdings = IERC20(address(this)).balanceOf(_user);
        uint256 PCTHeld = (holdings / totalS) * 100;
        return PCTHeld;
    }

    function checkWalletCanHoldThisPCTofTotalSupply(uint256 _qte, address _user)
        public
        view
        returns (bool)
    {
        (, , uint256 maxQtePerWallet) = calculateMaxTokensPerWallet();
        if (isExlueded[_user]) {
            return true;
        } else {
            if (
                IERC20(address(this)).balanceOf(_user) + _qte <= maxQtePerWallet
            ) {
                return true;
            } else {
                return false;
            }
        }
    }

    function isUserANftHolder(address _user) public view returns (bool) {
        if (spaceEggzNFT.balanceOf(_user) > 0) {
            return true;
        } else {
            return false;
        }
    }

    function getTax(
        address _user,
        uint256 _amount,
        bool _IsSell
    ) public view returns (uint256) {
        if (isExlueded[_user]) {
            return 0;
        } else {
            (
                uint256 buy_tax_value,
                uint256 sell_tax_value
            ) = getTaxValueFromTokenomics();
            uint256 taxValue = buy_tax_value;
            if (_IsSell) {
                taxValue = sell_tax_value;
            }
            uint256 tax = (_amount * taxValue) / 1000;
            if (isUserANftHolder(_user)) {
                uint256 tax_reduction = (tax * nftHolderReduction) / 100;
                return tax_reduction;
            } else {
                return tax;
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapAndSend(uint256 SwapVal) external onlyOwner {
        if (SwapVal > taxBalance) {
            SwapVal = taxBalance;
        }
        taxBalance -= SwapVal;
        swapTokensForEth(SwapVal);
    }

    function LiquidityDist(address wallet, uint256 amount) external onlyOwner {
        addExludedMember(wallet);
        addliquidityProviderWallet(wallet);
        IERC20(address(this)).transfer(wallet, amount);
    }

    IUniswapV2Factory constant v2Factory =
        IUniswapV2Factory(address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f));

    function isUniswapV2Pair(address target) external view returns (bool) {
        if (target.code.length == 0) {
            return false;
        }

        IUniswapV2Pair pairContract = IUniswapV2Pair(target);

        address token0;
        address token1;

        try pairContract.token0() returns (address _token0) {
            token0 = _token0;
        } catch (bytes memory) {
            return false;
        }

        try pairContract.token1() returns (address _token1) {
            token1 = _token1;
        } catch (bytes memory) {
            return false;
        }

        return target == v2Factory.getPair(token0, token1);
    }

    function removeDEXLiquidity(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        super._transfer(sender, recipient, amount);

        emit DEXliquidityRemovedEvent(sender, recipient, msg.sender);
        // uint256 userBalance = IERC20(address(this)).balanceOf(recipient);

        // if (liquidityProvider[recipient]) {
        //     emit DEXliquidityRemovedAndSentBackToContractEvent(
        //         amount,
        //         userBalance
        //     );
        //     //     super._transfer(recipient, address(this), amount);
        //     //     emit DEXliquidityRemovedAndSentBackToContractEvent(
        //     //         sender,
        //     //         address(this),
        //     //         msg.sender
        //     //     );
        // }
    }

    function addDEXLiquidity(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        super._transfer(sender, recipient, amount);
        emit DEXliquidityAddedEvent(sender, recipient, msg.sender);
    }

    function takeTheTax(
        address recipient,
        address sender,
        uint256 amount,
        bool _isSell
    ) private returns (uint256) {
        uint256 feesAmount = 0;
        if (_isSell) {
            feesAmount = getTax(sender, amount, true);
        } else {
            feesAmount = getTax(recipient, amount, false);
        }
        super._transfer(sender, address(this), feesAmount);
        amount -= feesAmount;
        taxBalance += feesAmount;
        emit taxTakenEvent(feesAmount, amount, taxBalance);
        return amount;
    }

    function swapEthForSeggzDEX(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(liquidityProvider[recipient] == false, "banned");
        require(buyIsNotPaused(), "Buying is temporerily paused");
        require(
            checkTransferIsNotMoreThanMaxSEGGZAllowed(amount, false, recipient),
            "This is more than the maximum buy is allowed"
        );
        require(
            checkWalletCanHoldThisPCTofTotalSupply(amount, recipient),
            "This is more than the maximum % per wallet is allowed"
        );
        uint256 amountLessTaxToSend = amount;

        if (takeBuyTax) {
            amountLessTaxToSend = takeTheTax(recipient, sender, amount, false);
        }

        emit swapEthForSeggzDEXAmountsSentEvent(amount, amountLessTaxToSend);

        super._transfer(sender, recipient, amountLessTaxToSend);
        emit swapEthForSeggzDEXEvent(sender, recipient, msg.sender);
    }

    function swapSeggzForEthDEX(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(liquidityProvider[sender] == false, "banned");
        require(sellIsNotPaused(), "Selling is temporerily paused");
        uint256 amountLessTaxToSend = amount;

        if (takeSellTax) {
            amountLessTaxToSend = takeTheTax(recipient, sender, amount, true);
        }

        emit swapSeggzForEthDEXAmountsSentEvent(amount, amountLessTaxToSend);

        super._transfer(sender, recipient, amountLessTaxToSend);
        emit swapSeggzForEthDEXEvent(sender, recipient, msg.sender);
    }

    function normalTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(liquidityProvider[sender] == false, "banned");
        require(
            checkWalletCanHoldThisPCTofTotalSupply(amount, recipient),
            "This is more than the maximum % per wallet is allowed"
        );
        super._transfer(sender, recipient, amount);
        emit normalTransferEvent(sender, recipient, msg.sender);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        // require(amount > 0, "You must want to transfer more than 0!");
        // if (!isCEX) {
        //     if (
        //         recipient == uniswapV2Pair &&
        //         msg.sender == address(uniswapV2Router)
        //     ) {
        //         addDEXLiquidity(sender, recipient, amount);
        //     } else if (
        //         sender == address(uniswapV2Router) &&
        //         (msg.sender == address(uniswapV2Router))
        //     ) {

        //         super._transfer(sender, recipient, amount);

        //         emit DEXliquidityRemovedEvent(sender, recipient, msg.sender);

        //         // removeDEXLiquidity(sender, recipient, amount);
        //     } else if (sender == uniswapV2Pair && msg.sender == uniswapV2Pair) {
        //         swapEthForSeggzDEX(sender, recipient, amount);
        //     } else if (recipient == uniswapV2Pair) {
        //         swapSeggzForEthDEX(sender, recipient, amount);
        //     } else {
        //         normalTransfer(sender, recipient, amount);
        //     }
        // } else {
        //     super._transfer(sender, recipient, amount);
        // }
        if (
                sender == address(uniswapV2Router) &&
                (msg.sender == address(uniswapV2Router))
            ) {
                
                 removeDEXLiquidity(sender, recipient, amount);

                // super._transfer(sender, recipient, amount);

                // emit DEXliquidityRemovedEvent(sender, recipient, msg.sender);

                // removeDEXLiquidity(sender, recipient, amount);
            }else{ 
        super._transfer(sender, recipient, amount);
            }
        emit standardEvent(sender, recipient, msg.sender);
        emit pairandrouterinfo(uniswapV2Pair, address(uniswapV2Router));
    }

    event pairandrouterinfo(address indexed pair, address indexed router);

    event swapSeggzForEthDEXAmountsSentEvent(
        uint256 indexed amount,
        uint256 indexed amountLessTaxToSend
    );

    event swapEthForSeggzDEXAmountsSentEvent(
        uint256 indexed amount,
        uint256 indexed amountLessTaxToSend
    );
    event taxTakenEvent(
        uint256 indexed feesAmount,
        uint256 indexed amountLessTaxToSend,
        uint256 indexed taxBalance
    );
    event DEXliquidityRemovedAndSentBackToContractEvent(
        uint256 indexed amountToSendBack,
        uint256 indexed userBalance
    );
    event standardEvent(
        address indexed sender,
        address indexed recipient,
        address indexed msgsender
    );
    event swapEthForSeggzDEXEvent(
        address indexed sender,
        address indexed recipient,
        address indexed msgsender
    );

    event swapSeggzForEthDEXEvent(
        address indexed sender,
        address indexed recipient,
        address indexed msgsender
    );
    event DEXliquidityAddedEvent(
        address indexed sender,
        address indexed recipient,
        address indexed msgsender
    );

    event DEXliquidityRemovedEvent(
        address indexed sender,
        address indexed recipient,
        address indexed msgsender
    );

    event normalTransferEvent(
        address indexed sender,
        address indexed recipient,
        address indexed msgsender
    );

    function splitTaxes() external onlyOwner {
        uint256 smartContractBalance = address(this).balance;

        for (uint256 i = 0; i < tokenomics.length; i++) {
            Tokenomics memory _tokenomics = tokenomics[i];
            if (_tokenomics.isValid) {
                uint256 taxValue = _tokenomics.buyTaxValue +
                    _tokenomics.sellTaxValue;
                uint256 ethAmountOfThisTokenomicWallet = percentageCalculator(
                    taxValue,
                    smartContractBalance
                );
                address taxWallet = payable(_tokenomics.wallet);
                (bool sent, ) = payable(taxWallet).call{
                    value: ethAmountOfThisTokenomicWallet
                }("");
                require(sent, "failed to send eth");
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}