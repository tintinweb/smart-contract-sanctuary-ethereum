// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract LionVault is ERC721, Ownable, ReentrancyGuard {
    uint256 private _currentTokenId = 0;//Token ID here will start from 1
    uint256 BASIC_COST = 8;
    uint256 DEFAULT_ARP = 5 * 10 ** 3;
    uint256 MAX_ARP = 60 * 10 ** 3;
    uint256 DURATION = 180 days;
    uint256 EXTENSION_DURATION = 180 days;
    uint256 NEXT_CLAIM_DURATION = 30 days;
    uint256 TIK = 125;
    uint256 BASIC_BOOST_COST = 1;
    uint256 EXTENSION_COST = 440;
    address[] allowedContracts;
    string[] allowedCurrencies;  
    address public DMS = 0x631C2f0EdABaC799f07550aEE4fF0Bf7fd35212B; // mainnet or rinkeby DMS token address, not exist currently
    address public constant USDT = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // mainnet or rinkeby DAI token address rinkeby: 0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet or rinkeby WETH9 token address rinkeby: 0xc778417E063141139Fce010982780140Aa0cD5Ab
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // mainnet or rinkeby USDC token address rinkeby:0xeb8f08a975Ab53E34D8a0330E0D34de942C95926
    address administrativeWallet;
    struct Promotion {
        address promoAddress;
        uint256 depositAmount;
        uint256 starttime;
        uint256 lastClaimTime;
        uint256 lastClaimed;
        uint256 claimedInterest;
    }
    struct VaultData {
        bool active;
        address owner;
        uint256 ARP;
        uint256 duration;
        uint256 starttime;
        uint256 depositAmount;
        uint256 totalAmount;
        string referralHash;
        address referralAddress;
        uint256 referralFee;
        uint256 lastClaimTime;
        uint256 maxClaimAvailable;
        uint256 lastClaimed;
        uint256 claimedInterest;
        address[] promotions;
    }
    mapping(uint256 => mapping(address => Promotion)) promotionData;
    mapping(address => mapping(uint256 => bool)) public alreadyUsedTokenIdMap;
    mapping(uint256 => VaultData) public vaultDataByTokenID;
    mapping(string => address) public allowedTokenAddress;
    using Strings for uint256;
    
    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;
    // Base URI
    string private _baseURIextended;

    event Minted(address, uint256);
    event Deposited(uint256, address, uint256);
    event Withdrawn(uint256, address, uint256, uint256);
    event Claimed(uint256, address, uint256, uint256);
    event ReDeposited(uint256, address, uint256, uint256);
    ISwapRouter public immutable swapRouter;

    constructor(
        string memory _name, // random string VaultNFT
        string memory _symbol, // random string VNFT
        ISwapRouter _swapRouter, // mainnet or rinkeby V3 swapRouter address, rinkeby: 0xE592427A0AEce92De3Edee1F18E0157C05861564, mainnet: 0xE592427A0AEce92De3Edee1F18E0157C05861564
        address _administrativeWallet, // wallet address for provide fee
        string memory _baseTokenURI
    ) ERC721(_name, _symbol) {
        swapRouter = _swapRouter;
        administrativeWallet = _administrativeWallet;
        setBaseURI(_baseTokenURI);
        allowedTokenAddress["usdt"] = USDT;
        allowedTokenAddress["usdc"] = USDC;
        allowedTokenAddress["weth"] = WETH9;
    }
    
    function setBaseURI(string memory baseURI_) public onlyOwner() {
        _baseURIextended = baseURI_;
    }
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }
    /**
     * @dev Mints a token to an address with a tokenURI.
     */
    function mint(address _nftContract, uint256 _tokenId, uint256 _boost) external {
        if (msg.sender != owner()) {
            require(_isAllowedContract(_nftContract), "The Contract address is not allowed");
            require(IERC721(_nftContract).ownerOf(_tokenId) == msg.sender, "You are not owner of this NFT");
            require(!alreadyUsedTokenIdMap[_nftContract][_tokenId], "Token Token Id is already used to mint Vault");
            require(IERC20(DMS).balanceOf(msg.sender) >= BASIC_COST * 10 ** 18, "Insufficient DMS token balance to mint Vault NFT");
            TransferHelper.safeApprove(DMS, address(this), BASIC_COST * 10 ** 18 + _boost * 10 ** 18);
            TransferHelper.safeTransferFrom(DMS, msg.sender, address(this), BASIC_COST * 10 ** 18 + _boost * 10 ** 18);
        }
        uint256 arp = DEFAULT_ARP;
        if (_boost > 0) {
            require(_boost >= BASIC_BOOST_COST, "Insufficient Minimum Boost amount");
            require(EXTENSION_COST >= _boost, "Exceed Maximum Boost amount");
            require(IERC20(DMS).balanceOf(msg.sender) >= BASIC_COST * 10 ** 18 + _boost * 10 ** 18, "Insufficient DMS token balance to mint Vault NFT");
            arp = arp + _boost * TIK;
        }
        uint256 newTokenId = _getNextTokenId();
        _mint(msg.sender, newTokenId);
        _incrementTokenId();
        alreadyUsedTokenIdMap[_nftContract][_tokenId] = true;
        emit Minted(msg.sender, newTokenId);

        VaultData memory data;
        data.active = true;
        data.ARP = arp;
        data.duration = DURATION;
        data.starttime = block.timestamp;
        data.lastClaimed = 0;
        data.maxClaimAvailable = 6;
        vaultDataByTokenID[newTokenId] = data;
    }
    /**
     * @dev deposit token
     * @param _tokenId Vault NFT token ID, 
     * @param _token token name, 
     * @param _amount amount to deposit, 
     */
     function deposit(uint256 _tokenId, string memory _token, uint256 _amount) external payable {
        require(balanceOf(msg.sender) > 0, "You don't have any Vault NFT");
        require(ownerOf(_tokenId) == msg.sender, "You are not owner of this Vault NFT");
        require(_isAllowedCurrency(_token), "The token is not allowed to deposit");

        if (keccak256(abi.encodePacked(_token)) == keccak256(abi.encodePacked("eth"))) {
            require(msg.value == _amount, "Invalid ether balance");
        } else {
            require(IERC20(allowedTokenAddress[_token]).balanceOf(msg.sender) > _amount, "Insufficient token balance");
            TransferHelper.safeApprove(allowedTokenAddress[_token], address(this), _amount);
            TransferHelper.safeTransferFrom(allowedTokenAddress[_token], msg.sender, address(this), _amount);
        }
        uint256 depositAmount = _amount;
        if (keccak256(abi.encodePacked(_token)) != keccak256(abi.encodePacked("usdc")) || keccak256(abi.encodePacked(_token)) != keccak256(abi.encodePacked("usdt"))) {
            uint256 amountOut = convertExactTokenToStable(allowedTokenAddress[_token], _amount);
            depositAmount = amountOut;
        }
        vaultDataByTokenID[_tokenId].depositAmount = depositAmount;
        vaultDataByTokenID[_tokenId].totalAmount += depositAmount;
        emit Deposited(_tokenId, msg.sender, depositAmount);
     }

    /**
     * @dev deposit token from Referral link
     * @param _tokenId Vault NFT token ID, 
     * @param _token token name, 
     * @param _amount amount to deposit, 
     */
     function depositFromReferral(uint256 _tokenId, string memory _token, uint256 _amount, string memory referral) external payable {
        require(_isValidReferral(_tokenId, referral), "Invalid referral link");
        require(_isAllowedCurrency(_token), "The token is not allowed to deposit");

        if (keccak256(abi.encodePacked(_token)) == keccak256(abi.encodePacked("eth"))) {
            require(msg.value == _amount, "Invalid ether balance");
        } else {
            require(IERC20(allowedTokenAddress[_token]).balanceOf(msg.sender) > _amount, "Insufficient token balance");
            TransferHelper.safeApprove(allowedTokenAddress[_token], address(this), _amount);
            TransferHelper.safeTransferFrom(allowedTokenAddress[_token], msg.sender, address(this), _amount);
        }
        uint256 depositAmount = _amount;
        if (keccak256(abi.encodePacked(_token)) != keccak256(abi.encodePacked("usdc")) || keccak256(abi.encodePacked(_token)) != keccak256(abi.encodePacked("usdt"))) {
            uint256 amountOut = convertExactTokenToStable(allowedTokenAddress[_token], _amount);
            depositAmount = amountOut;
        }

        Promotion memory promo;
        promo.depositAmount = depositAmount;
        promo.promoAddress = msg.sender;
        promo.starttime = block.timestamp;
        promo.lastClaimed = vaultDataByTokenID[_tokenId].lastClaimed;
        // add new referral user into vault
        vaultDataByTokenID[_tokenId].totalAmount += depositAmount;

        bool flag = false; // check if the user already deposited token
        for (uint256 i = 0; i < vaultDataByTokenID[_tokenId].promotions.length; i ++) {
            if (vaultDataByTokenID[_tokenId].promotions[i] == msg.sender) {
                promotionData[i][msg.sender].depositAmount  += depositAmount;
                flag = true;
            }
        }
        if (!flag) { // if it's new deposit
            promotionData[_tokenId][msg.sender] = promo;
            vaultDataByTokenID[_tokenId].promotions.push(msg.sender);
        }
        emit Deposited(_tokenId, msg.sender, depositAmount);
    }

    /**
     * @dev extend vault period
     * @param _tokenId vault NFT Id
      */
    function extendPeriodOfVault(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "You are not owner of this Vault NFT");
        require(IERC20(DMS).balanceOf(msg.sender) >= EXTENSION_COST * 10 ** 18, "Insufficient DMS token balance to mint Vault NFT");
        TransferHelper.safeApprove(DMS, address(this), EXTENSION_COST * 10 ** 18);
        TransferHelper.safeTransferFrom(DMS, msg.sender, address(this), EXTENSION_COST * 10 ** 18);
        vaultDataByTokenID[_tokenId].maxClaimAvailable += 6;
    }

    /**
     * @dev withdraw capital from vault
     * @param _tokenId vault NFT Id
      */
    function withdraw(uint256 _tokenId, bool reDeposit) external nonReentrant {
        require(block.timestamp >= vaultDataByTokenID[_tokenId].starttime + vaultDataByTokenID[_tokenId].maxClaimAvailable * 30 days, "The vault is still locked");

        uint256 depositAmount = 0;
        uint256 remainedInterest = 0;
        if (msg.sender == vaultDataByTokenID[_tokenId].owner) {
            depositAmount = vaultDataByTokenID[_tokenId].depositAmount;
            remainedInterest = vaultDataByTokenID[_tokenId].depositAmount * vaultDataByTokenID[_tokenId].ARP * ((vaultDataByTokenID[_tokenId].maxClaimAvailable - vaultDataByTokenID[_tokenId].lastClaimed) / 12) / 10 ** 5;
            require(depositAmount > 0, "You are not investor");
            if (reDeposit == true) {
                require(IERC20(USDC).balanceOf(address(this)) > remainedInterest, "Insufficient Contract balance");
                vaultDataByTokenID[_tokenId].starttime = block.timestamp;
                vaultDataByTokenID[_tokenId].lastClaimed = 0;
                vaultDataByTokenID[_tokenId].lastClaimTime = 0;
                vaultDataByTokenID[_tokenId].maxClaimAvailable = 6;
                TransferHelper.safeTransferFrom(DMS, address(this), msg.sender, remainedInterest);
                emit ReDeposited(_tokenId, msg.sender, remainedInterest, block.timestamp);
            } else {
                require(IERC20(USDC).balanceOf(address(this)) > depositAmount + remainedInterest, "Insufficient Contract balance");
                vaultDataByTokenID[_tokenId].depositAmount = 0;
                vaultDataByTokenID[_tokenId].lastClaimed = vaultDataByTokenID[_tokenId].maxClaimAvailable;
                vaultDataByTokenID[_tokenId].lastClaimTime = block.timestamp;
                vaultDataByTokenID[_tokenId].totalAmount -= depositAmount;
                TransferHelper.safeTransferFrom(DMS, address(this), msg.sender, depositAmount + remainedInterest);
                emit Withdrawn(_tokenId, msg.sender, depositAmount + remainedInterest, block.timestamp);
            }
        } else {
            for (uint256 i = 0; i < vaultDataByTokenID[_tokenId].promotions.length; i ++) {
                if (vaultDataByTokenID[_tokenId].promotions[i] == msg.sender) {
                    depositAmount = promotionData[_tokenId][msg.sender].depositAmount;
                    remainedInterest = promotionData[_tokenId][msg.sender].depositAmount * vaultDataByTokenID[_tokenId].ARP * ((vaultDataByTokenID[_tokenId].maxClaimAvailable - promotionData[_tokenId][msg.sender].lastClaimed) / 12) / 10 ** 5;
                    require(depositAmount > 0, "You are not investor");
                    if (reDeposit == true) {
                        require(IERC20(USDC).balanceOf(address(this)) > remainedInterest, "Insufficient Contract balance");
                        promotionData[_tokenId][msg.sender].lastClaimed = 0;
                        vaultDataByTokenID[_tokenId].maxClaimAvailable = 6;
                        vaultDataByTokenID[_tokenId].lastClaimTime = block.timestamp;
                        TransferHelper.safeTransferFrom(DMS, address(this), msg.sender, remainedInterest);
                        emit ReDeposited(_tokenId, msg.sender, remainedInterest, block.timestamp);
                    } else {
                        require(IERC20(USDC).balanceOf(address(this)) > depositAmount + remainedInterest, "Insufficient Contract balance");
                        delete vaultDataByTokenID[_tokenId].promotions[i];
                        vaultDataByTokenID[_tokenId].totalAmount -= depositAmount;
                        TransferHelper.safeTransferFrom(DMS,address(this), msg.sender,  depositAmount + remainedInterest);
                        emit Withdrawn(_tokenId, msg.sender, depositAmount + remainedInterest, block.timestamp);
                    }
                }
            }
        }
    }

    /**
     * @dev claim from vault
     * @param _tokenId vault NFT Id
      */
    function claim(uint256 _tokenId) external nonReentrant {
        uint256 interest = 0;
        if (msg.sender == vaultDataByTokenID[_tokenId].owner) {
            require(block.timestamp >= vaultDataByTokenID[_tokenId].starttime + (vaultDataByTokenID[_tokenId].lastClaimed + 1 ) * 30 days, "Claim is still locked");
            require(vaultDataByTokenID[_tokenId].maxClaimAvailable > vaultDataByTokenID[_tokenId].lastClaimed, "Claim is ended");
            require(vaultDataByTokenID[_tokenId].depositAmount > 0, "Insufficient deposit balance");
            interest = vaultDataByTokenID[_tokenId].depositAmount * vaultDataByTokenID[_tokenId].ARP  / 12 / 10 ** 5;
            require(IERC20(USDC).balanceOf(address(this)) >= interest, "Insufficient Contract balance");
            vaultDataByTokenID[_tokenId].lastClaimed += 1;
            vaultDataByTokenID[_tokenId].lastClaimTime += 30 days;
            vaultDataByTokenID[_tokenId].claimedInterest += interest;
            TransferHelper.safeTransferFrom(DMS, address(this), administrativeWallet, interest / 2);
            TransferHelper.safeTransferFrom(DMS, address(this), msg.sender, interest / 2);
            emit Claimed(_tokenId, msg.sender, interest / 2, block.timestamp);
        } else {
            for (uint256 i = 0; i < vaultDataByTokenID[_tokenId].promotions.length; i ++) {
                if (vaultDataByTokenID[_tokenId].promotions[i] == msg.sender) {
                    require(block.timestamp >= vaultDataByTokenID[_tokenId].starttime +  (promotionData[_tokenId][msg.sender].lastClaimed + 1 ) * 30 days, "Claim is still locked");
                    require(vaultDataByTokenID[_tokenId].maxClaimAvailable > promotionData[_tokenId][msg.sender].lastClaimed, "Claim is ended");
                    require(promotionData[_tokenId][msg.sender].depositAmount > 0, "Insufficient deposit balance");
                    interest = promotionData[_tokenId][msg.sender].depositAmount * vaultDataByTokenID[_tokenId].ARP / 12 / 10 ** 5;
                    require(IERC20(USDC).balanceOf(address(this)) >= interest, "Insufficient Contract balance");
                    promotionData[_tokenId][msg.sender].lastClaimed += 1;
                    promotionData[_tokenId][msg.sender].lastClaimTime += 30 days;
                    promotionData[_tokenId][msg.sender].claimedInterest += interest;
                    TransferHelper.safeTransferFrom(DMS, address(this), administrativeWallet, interest / 2);
                    TransferHelper.safeTransferFrom(DMS, address(this), vaultDataByTokenID[_tokenId].referralAddress,  interest / 2 * vaultDataByTokenID[_tokenId].referralFee / 100);
                    TransferHelper.safeTransferFrom(DMS,address(this), msg.sender,   interest / 2 * (100 - vaultDataByTokenID[_tokenId].referralFee) / 100);
                    emit Claimed(_tokenId, msg.sender, interest / 2 * (100 - vaultDataByTokenID[_tokenId].referralFee) / 100, block.timestamp);
                }
            }
        }
    }

    /**
     * @dev generate Referral Link
=     * @param _tokenId vault NFT Id, 
=     * @param referralWallet referral wallet to recieve claim fee, 
=     * @param referralFee fee Rate, 
     */
    function generateReferralLink(uint256 _tokenId, address referralWallet, uint256 referralFee) external returns (string memory) {
        require(keccak256(abi.encodePacked(vaultDataByTokenID[_tokenId].referralHash))  == keccak256(abi.encodePacked('')), "Referral Link already generated"); //keccak256(abi.encodePacked('Solidity')) 
        require(vaultDataByTokenID[_tokenId].owner == msg.sender, "You are not owner of this vault");
        string memory str = Strings.toString(_tokenId + block.timestamp);
        string memory referralHash = Base64.encode(bytes(str));
        vaultDataByTokenID[_tokenId].referralHash = referralHash;
        vaultDataByTokenID[_tokenId].referralAddress = referralWallet;
        vaultDataByTokenID[_tokenId].referralFee = referralFee;
        return referralHash;
    }

    /**
     * @dev deposit token
=     * @param _address token name to swap, 
      * @param _amount amount to swap, 
     */
    function convertExactTokenToStable(address _address, uint256 _amount)  internal returns (uint256 amountOut) {
        require(_amount > 0, "Must pass non 0 amount");
        TransferHelper.safeApprove(_address, address(swapRouter), _amount);

        uint256 deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
        address tokenIn = _address;
        address tokenOut = USDC;
        uint24 fee = 3000;
        address recipient = address(this);
        uint256 amountIn = _amount;
        uint256 amountOutMinimum = 1;
        uint160 sqrtPriceLimitX96 = 0;
        
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            tokenIn,
            tokenOut,
            fee,
            recipient,
            deadline,
            amountIn,
            amountOutMinimum,
            sqrtPriceLimitX96
        );
        
        amountOut = swapRouter.exactInputSingle(params);
        return amountOut;
    }
    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId+1;
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        _currentTokenId++;
    }

    // /**
    // *  @dev recover tokens of contract
    // *  @param  _tokenAddress  token address to recover
    // *  @param  _amount  token amount to amount
    //  */

    // function recover_token(address _tokenAddress, uint256 _amount) external onlyOwner {
    //     require(IERC20(USDC).balanceOf(_tokenAddress) > _amount, "Insufficient Contract balance");
    //     TransferHelper.safeTransferFrom(_tokenAddress, address(this), msg.sender, _amount);
    // } 

    /**
    *  @dev set MAX APR
    *  @param  _maxApr  new APR value
     */
    function _setMaxAPR (uint256 _maxApr) external onlyOwner {
        require(_maxApr > 0, "Invalid Max APR value");
        MAX_ARP = _maxApr * 10 ** 3;
    } 

    /**
    *  @dev set currency to be allowed to deposit
    *  @param  _token  token name to be added
    *  @param  _address  token address to be added
     */
    function _setAllowedCurrency (string memory _token, address _address) external onlyOwner {
        bool flag = false;
        for (uint256 i = 0; i < allowedCurrencies.length; i ++) {
            if (keccak256(abi.encodePacked(allowedCurrencies[i])) == keccak256(abi.encodePacked(_token))) {
                flag = true;
                break;
            }
        }
        if (!flag) {
            allowedCurrencies.push(_token);
            allowedTokenAddress[_token] = _address;
        }
    } 

    /**
    *  @dev delete token from allowed currency list
    *  @param  _token  token name to be deleted
     */
    function _deleteAllowedCurrency (string memory _token) external onlyOwner {
        for (uint256 i = 0; i < allowedCurrencies.length; i ++) {
            if (keccak256(abi.encodePacked(allowedCurrencies[i])) == keccak256(abi.encodePacked(_token))) {
                delete allowedCurrencies[i];
                delete allowedTokenAddress[_token];
                break;
            }
        }
    } 

    /**
    *  @dev return whitelisted token list
    *  @return  whitelisted token list
     */
    function _getAllowedCurrency () public view returns (string[] memory, address[] memory tokenAddress ) {
        address[] memory tokenAddresses;
        for (uint256 i = 0; i < allowedCurrencies.length; i ++) {
            tokenAddresses[i] = allowedTokenAddress[allowedCurrencies[i]];
        }
        return (allowedCurrencies, tokenAddresses);
    }
    
    /**
    *  @dev check if the token is whitelisted
    *  @return  true or false
     */
    function _isAllowedCurrency (string memory _token) private view returns (bool) {
        bool flag = false;
        for (uint256 i = 0; i < allowedCurrencies.length; i ++) {
            if (keccak256(abi.encodePacked(allowedCurrencies[i])) ==keccak256(abi.encodePacked(_token))) {
                flag = true;
                break;
            }
        }
        return flag;
    }   

     /**
    *  @dev set nft smart contract to be allowed to create vaultNFT
    *  @param  _contract  nft smart contract address to be added
     */
    function _setAllowedContract (address _contract) external onlyOwner {
        bool flag = false;
        for (uint256 i = 0; i < allowedContracts.length; i ++) {
            if (allowedContracts[i] == _contract) {
                flag = true;
                break;
            }
        }
        if (!flag) {
            allowedContracts.push(_contract);
        }
    } 

    /**
    *  @dev delete contract address from whitelist
    *  @param  _contract  nft smart contract address to be deleted
     */
    function _deleteAllowedContract (address _contract) external onlyOwner {
        for (uint256 i = 0; i < allowedContracts.length; i ++) {
            if (allowedContracts[i] == _contract) {
                delete allowedContracts[i];
                break;
            }
        }
    } 

    /**
    *  @dev return whitelisted nft contract addresses
    *  @return  whitelisted contract address list
     */
    function _getAllowedContract () public view returns (address[] memory ) {
        return allowedContracts;
    }
    
    /**
    *  @dev check if the address is whitelisted
    *  @return  true or false
     */
    function _isAllowedContract (address _contract) private view returns (bool) {
        bool flag = false;
        for (uint256 i = 0; i < allowedContracts.length; i ++) {
            if (allowedContracts[i] == _contract) {
                flag = true;
                break;
            }
        }
        return flag;
    }  

    /**
    *  @dev check if the referral link is valid
    *  @return  true or false
     */
    function _isValidReferral (uint256 _tokenId, string memory _referral) private view returns (bool) {
        bool flag = false;
        // validation code here
        if (keccak256(abi.encodePacked(vaultDataByTokenID[_tokenId].referralHash)) == keccak256(abi.encodePacked(_referral))) {
            flag = true;
        }
        return flag;
    }   

    /**
    *  @dev set Administrative wallet to collect fee
    *  @param  _newAdminAddress new administrative wallet address
     */
    function _setAdministrativeWallet (address _newAdminAddress) external onlyOwner {
        administrativeWallet = _newAdminAddress;
    }

    /**
    *  @dev calculate total fee
    *  @return  total fee to be distributed
     */
    function _calculateVaultFeeForNextClaim () external view onlyOwner returns (uint256) {
        uint256 interest = 0;
        for (uint256 i = 0; i <= _currentTokenId; i ++) {
            if (vaultDataByTokenID[i].depositAmount > 0) {
                interest += vaultDataByTokenID[i].depositAmount * vaultDataByTokenID[i].ARP  / 12 / 10 ** 5;
            }
            for (uint256 j = 0; j < vaultDataByTokenID[i].promotions.length; i ++) {
                interest = promotionData[i][vaultDataByTokenID[i].promotions[j]].depositAmount * vaultDataByTokenID[i].ARP / 12 / 10 ** 5;
            }
        }
        return interest;
    }  
    receive() external payable{}
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}