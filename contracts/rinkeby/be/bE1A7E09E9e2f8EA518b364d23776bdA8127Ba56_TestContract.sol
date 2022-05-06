//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

struct OpenseaTrades {
    uint256 value;
    bytes tradeData;
}

struct functionCall{
    uint256 value;
    address callAddress;
    bytes callData;
}

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

interface IUniswap {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
        
        
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
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
    
  function swapTokensForExactTokens(
      uint amountOut,
      uint amountInMax,
      address[] calldata path,
      address to,
      uint deadline
    ) external returns (uint[] memory amounts);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface INFTXVault{
    function mint(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts /* ignored for ERC721 vaults */
    ) external returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

struct TradeDataIn{
    OpenseaTrades openseaTrade;
    address collectionAddress;
    uint256 tokenId;
    address nftxVaultAddress;
    address uniswapRouterAddress;
    uint256 numTokens;
    uint256 slippage;
    address WETHAddress;
}

contract TestContract {
    // IWETH private constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // IOpenseaWyvern private constant openseaWyvern = IOpenseaWyvern(0x7f268357A8c2552623316e2562D90e642bB538E5);
    // IOpenseaWyvern private constant openseaWyvern = IOpenseaWyvern(0xdD54D660178B28f6033a953b0E55073cFA7e3744);


    address private owner;

    constructor() {
		owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _o) onlyOwner external {
		owner = _o;
	}

    function testOrder(uint256 value,
            bytes memory tradeData,
            address collectionAddress,
            uint256 tokenId,
            address nftxVaultAddress,
            address uniswapRouterAddress,
            uint256 numTokens,
            uint256 slippage,
            address WETHAddress) onlyOwner payable external {
        //Buy NFT from opensea
        address(0xdD54D660178B28f6033a953b0E55073cFA7e3744).call{value:value}(tradeData);

        //Approve NFTX for NFT token
        IERC721 nftContract = IERC721(collectionAddress);
        
        if(!nftContract.isApprovedForAll(address(this), nftxVaultAddress)){
            nftContract.setApprovalForAll(nftxVaultAddress, true);
        }

        //Mint tokens
        INFTXVault nftxVault = INFTXVault(nftxVaultAddress);
        uint256[] memory tokenArray;
        tokenArray[0] = tokenId;

        uint256[] memory tokenAmountArr;

        nftxVault.mint(tokenArray, tokenAmountArr);

        //Approve sushiswap on tokens
        if(nftxVault.allowance(address(this), uniswapRouterAddress) < numTokens){
            nftxVault.approve(uniswapRouterAddress, numTokens);
        }

        //swap for eth and send to caller
        IUniswap uniswap = IUniswap(uniswapRouterAddress);

        address[] memory path = new address[](2);// = [nftxVaultAddress, WETHAddress];
        path[0] = nftxVaultAddress;
        path[1] = WETHAddress;
        
        uniswap.swapExactTokensForETH(numTokens, numTokens * slippage / 1000, path, address(this), block.timestamp + 5 minutes);
    }

    function buyNFT(uint256 value, bytes memory tradeData) onlyOwner payable external{
            address(0xdD54D660178B28f6033a953b0E55073cFA7e3744).call{value:value}(tradeData); 
    }

    function approveNFTX(address collectionAddress, address nftxVaultAddress) onlyOwner external{
        //Approve NFTX for NFT token
        IERC721 nftContract = IERC721(collectionAddress);
        
        if(!nftContract.isApprovedForAll(address(this), nftxVaultAddress)){
            nftContract.setApprovalForAll(nftxVaultAddress, true);
        }
    }

    function mintNFTX(address nftxVaultAddress, uint256 tokenId ) onlyOwner external{
        //Mint tokens
        INFTXVault nftxVault = INFTXVault(nftxVaultAddress);
        uint256[] memory tokenArray;
        tokenArray[0] = tokenId;

        uint256[] memory tokenAmountArr;
        tokenAmountArr[0] = 1;

        nftxVault.mint(tokenArray, tokenAmountArr);
    }

    function approveSushiSwap(address nftxVaultAddress, address uniswapRouterAddress, uint256 numTokens) onlyOwner external{
        //Approve sushiswap on tokens

        INFTXVault nftxVault = INFTXVault(nftxVaultAddress);
        if(nftxVault.allowance(address(this), uniswapRouterAddress) < numTokens){
            nftxVault.approve(uniswapRouterAddress, numTokens);
        }
    }

    function convertToETH(address nftxVaultAddress,
                            address uniswapRouterAddress,
                            uint256 numTokens,
                            uint256 slippage,
                            address WETHAddress) onlyOwner external{
        //swap for eth and send to caller
        IUniswap uniswap = IUniswap(uniswapRouterAddress);

        address[] memory path = new address[](2);// = [nftxVaultAddress, WETHAddress];
        path[0] = nftxVaultAddress;
        path[1] = WETHAddress;
    
        uniswap.swapExactTokensForETH(numTokens, numTokens * slippage / 1000, path, address(this), block.timestamp + 5 minutes);
    }


    function transferNFT(address collectionAddress, uint256 tokenId) onlyOwner external{
        IERC721 nftContract = IERC721(collectionAddress);
        nftContract.transferFrom(address(this), msg.sender, tokenId);
    } 

    function withdrawAll() onlyOwner external {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    } 

    function callFunction(functionCall calldata call) onlyOwner public payable {
        address(call.callAddress).call{value:call.value}(call.callData); 
    }

    function multiCall(functionCall[] calldata calls) onlyOwner external payable {
        for(uint i  = 0; i < calls.length; i++){
            callFunction(calls[i]);
        }
    }


}