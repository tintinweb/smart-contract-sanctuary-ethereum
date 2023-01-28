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

contract BitRoyaleLand is ERC721Enumerable {
    uint256 public smallLandMintPrice = 0.27 ether;
    uint256 public mediumLandMintPrice = 0.33 ether;
    uint256 public largeLandMintPrice = 0.46 ether;

    uint256 public smallLandMaxSupply = 1000;
    uint256 public mediumLandMaxSupply = 750;
    uint256 public largeLandMaxSupply = 500;

    uint256 public smallLandTotalSupply = 0;
    uint256 public mediumLandTotalSupply = 0;
    uint256 public largeLandTotalSupply = 0;

    uint256 public smallLandTokenId = 0;
    uint256 public mediumLandTokenId = 1;
    uint256 public largeLandTokenId = 2;

    string _baseTokenURI;

    bool public isActive = true;
    IERC20 public BCOMP;
    address public WETH;

    event AssetMinted(uint256 tokenId, address sender);
    event SaleActivation(bool isActive);

    IUniswapV2Router02 public uniswapV2Router;

    constructor(address _bcomp) ERC721("Royale Lands", "RLAND") {
        BCOMP = IERC20(_bcomp);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        WETH = uniswapV2Router.WETH();
    }

    function mint(
        address _to,
        uint256 _count,
        uint256 price,
        uint256 landType
    ) public {
        if (msg.sender != owner()) {
            require(isActive, "Sale is not active currently.");
        }

        if (landType == 1) {
            require(
                smallLandTotalSupply + _count <= smallLandMaxSupply,
                "Total supply exceeded."
            );
        } else {
            if (landType == 2) {
                require(
                    mediumLandTotalSupply + _count <= mediumLandMaxSupply,
                    "Total supply exceeded."
                );
            } else {
                if (landType == 3) {
                    require(
                        largeLandTotalSupply + _count <= largeLandMaxSupply,
                        "Total supply exceeded."
                    );
                }
            }
        }

        require(landType < 4, "Land type between 1 and 3");
        require(landType > 0, "Land type between 1 and 3");

        if (landType == 1) {
            require(
                price >= _count * getAmountsOut(smallLandMintPrice),
                "Insuffient BCOMP amount sent"
            );
        } else {
            if (landType == 2) {
                require(
                    price >= _count * getAmountsOut(mediumLandMintPrice),
                    "Insuffient BCOMP amount sent"
                );
            } else {
                if (landType == 3) {
                    require(
                        price >= _count * getAmountsOut(largeLandMintPrice),
                        "Insuffient BCOMP amount sent"
                    );
                }
            }
        }

        BCOMP.transferFrom(msg.sender, address(this), price);

        for (uint256 i = 0; i < _count; i++) {
            if (landType == 1) {
                smallLandTokenId = smallLandTokenId + 3;
                emit AssetMinted(smallLandTokenId, _to);
                _safeMint(_to, smallLandTokenId);
            } else {
                if (landType == 2) {
                    mediumLandTokenId = mediumLandTokenId + 3;
                    emit AssetMinted(mediumLandTokenId, _to);
                    _safeMint(_to, mediumLandTokenId);
                } else {
                    if (landType == 3) {
                        largeLandTokenId = largeLandTokenId + 3;
                        emit AssetMinted(largeLandTokenId, _to);
                        _safeMint(_to, largeLandTokenId);
                    }
                }
            }
        }
    }

    function totalSupply() public view virtual override returns (uint256) {
        return
            smallLandTotalSupply + mediumLandTotalSupply + largeLandTotalSupply;
    }

    function setActive(bool val) public onlyOwner {
        isActive = val;
        emit SaleActivation(val);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setSmallLandMintPrice(uint256 _smallLandMintPrice)
        public
        onlyOwner
    {
        smallLandMintPrice = _smallLandMintPrice;
    }

    function setMediumLandMintPrice(uint256 _mediumLandMintPrice)
        public
        onlyOwner
    {
        mediumLandMintPrice = _mediumLandMintPrice;
    }

    function setLargeLandMintPrice(uint256 _largeLandMintPrice)
        public
        onlyOwner
    {
        largeLandMintPrice = _largeLandMintPrice;
    }

    function setSmallLandMaxSupply(uint256 _smallLandMaxSupply)
        public
        onlyOwner
    {
        smallLandMaxSupply = _smallLandMaxSupply;
    }

    function setMediumLandMaxSupply(uint256 _mediumLandMaxSupply)
        public
        onlyOwner
    {
        mediumLandMaxSupply = _mediumLandMaxSupply;
    }

    function setLargeLandMaxSupply(uint256 _largeLandMaxSupply)
        public
        onlyOwner
    {
        largeLandMaxSupply = _largeLandMaxSupply;
    }

    function setBCOMP(address _bcomp) public onlyOwner {
        BCOMP = IERC20(_bcomp);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
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

    function getAmountsOut(uint256 amount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(BCOMP);

        return uniswapV2Router.getAmountsOut(amount, path)[1];
    }

    function getPriceInBCOMP(uint8 landType) public view returns (uint256) {
        require(landType > 0 && landType < 4, "land type between 1 and 3");
        if (landType == 1) {
            return getAmountsOut(smallLandMintPrice);
        } else {
            if (landType == 2) {
                return getAmountsOut(mediumLandMintPrice);
            } else {
                return getAmountsOut(largeLandMintPrice);
            }
        }
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