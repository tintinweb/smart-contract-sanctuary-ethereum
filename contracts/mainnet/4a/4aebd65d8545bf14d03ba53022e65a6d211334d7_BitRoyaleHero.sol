// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// pragma solidity >=0.5.0;
interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// pragma solidity >=0.6.2;
interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
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

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

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

contract BitRoyaleHero is ERC721Enumerable {
    uint256 public mintPrice = 0.012 ether;

    bool public isActive = true;

    uint256 public maximumMintSupply = 30000;
    string private _baseTokenURI;
    IERC20 public BCOMP;
    address public WETH;

    mapping(address => uint256) public whitelist;
    bool public isWhitelist = true;

    IUniswapV2Router02 public uniswapV2Router;

    event AssetMinted(uint256 tokenId, address sender);
    event SaleActivation(bool isActive);
    event WhitelistActivation(bool isWhitelist);

    struct Whitelist {
        uint256 amount;
        address userAdr;
    }

    constructor(address _bcomp) ERC721("Royale Hero", "RHERO") {
        BCOMP = IERC20(_bcomp);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        WETH = uniswapV2Router.WETH();
    }

    modifier saleIsOpen() {
        require(totalSupply() <= maximumMintSupply, "Sale has ended.");
        _;
    }

    function setActive(bool val) public onlyOwner {
        isActive = val;
        emit SaleActivation(val);
    }

    function setMaxMintSupply(uint256 maxMintSupply) external onlyOwner {
        maximumMintSupply = maxMintSupply;
    }

    function setPrice(uint256 _price) public onlyOwner {
        mintPrice = _price;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() external view returns (uint256) {
        return mintPrice;
    }

    function getPriceInBCOMP() public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(BCOMP);

        return uniswapV2Router.getAmountsOut(mintPrice, path)[1];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setWhitelist(Whitelist[] memory _whitelist) public onlyOwner {
        for (uint256 i = 0; i < _whitelist.length; i++) {
            whitelist[_whitelist[i].userAdr] = _whitelist[i].amount;
        }
    }

    function mint(
        address _to,
        uint256 _count,
        uint256 price
    ) public saleIsOpen {
        if (msg.sender != owner()) {
            require(isActive, "Sale is not active currently.");
        }

        require(
            totalSupply() + _count <= maximumMintSupply,
            "Total supply exceeded."
        );

        require(
            price >= _count * getPriceInBCOMP(),
            "Insuffient BCOMP amount sent."
        );

        BCOMP.transferFrom(msg.sender, address(this), price);

        for (uint256 i = 0; i < _count; i++) {
            emit AssetMinted(totalSupply(), _to);
            _safeMint(_to, totalSupply());
        }
    }

    function setIsWhitelist (bool _isWhitelist) public onlyOwner {
      isWhitelist = _isWhitelist;
      emit WhitelistActivation(_isWhitelist);

    }

    function getWhitelisted(address _to) public saleIsOpen {
        require(isActive && isWhitelist, "Whitelist is not active currently.");

        require(whitelist[_to] > 0, "already claimed or not whitelisted!");
        require(
            totalSupply() + whitelist[_to] <= maximumMintSupply,
            "Total supply exceeded."
        );

        for (uint256 i = 0; i < whitelist[_to]; i++) {
            emit AssetMinted(totalSupply(), _to);
            _safeMint(_to, totalSupply());
        }

        whitelist[_to] = 0;
    }

    function batchReserveToMultipleAddresses(
        uint256 _count,
        address[] calldata addresses
    ) external onlyOwner {
        uint256 supply = totalSupply();

        require(supply + _count <= maximumMintSupply, "Total supply exceeded.");

        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add a null address");

            for (uint256 j = 0; j < _count; j++) {
                emit AssetMinted(totalSupply(), addresses[i]);
                _safeMint(addresses[i], totalSupply());
            }
        }
    }

    function setBCOMP(address _bcomp) public onlyOwner {
        BCOMP = IERC20(_bcomp);
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdrawBCOMP(uint256 _amount) external onlyOwner {
        require(
            _amount <= BCOMP.balanceOf(address(this)),
            "Not enough balance!"
        );
        BCOMP.transfer(_msgSender(), _amount);
    }

    function withdrawETH(uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;

        require(
            amount <= balance,
            "Withdrawable: you cannot remove this total amount"
        );

        Address.sendValue(payable(_msgSender()), amount);
    }

    function withdrawERC20(address tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        IERC20 tokenContract = IERC20(tokenAddress);

        uint256 balance = tokenContract.balanceOf(address(this));
        require(
            amount <= balance,
            "Withdrawable: you cannot remove this total amount"
        );

        require(
            tokenContract.transfer(_msgSender(), amount),
            "Withdrawable: Fail on transfer"
        );
    }

    receive() external payable {}
}