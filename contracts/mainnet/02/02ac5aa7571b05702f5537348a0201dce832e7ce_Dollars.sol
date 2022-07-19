// SPDX-License-Identifier: UNLICENSED
// All Rights Reserved

// Contract is not audited.
// Use authorized deployments of this contract at your own risk.

// NOTHING IN THIS COMMENT IS FINANCIAL ADVISE
// DO YOUR OWN RESEARCH TO VERIFY ANY STATEMENTS OR CLAIMS
// READ THE CONTRACT (WHICH HAS NOT BEEN AUDITED) BEFORE INTERACTING

/*
██████╗  ██████╗ ██╗     ██╗      █████╗ ██████╗ ███████╗
██╔══██╗██╔═══██╗██║     ██║     ██╔══██╗██╔══██╗██╔════╝
██║  ██║██║   ██║██║     ██║     ███████║██████╔╝███████╗
██║  ██║██║   ██║██║     ██║     ██╔══██║██╔══██╗╚════██║
██████╔╝╚██████╔╝███████╗███████╗██║  ██║██║  ██║███████║
╚═════╝  ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝

╔╦╗┌─┐┌─┐┌─┐┌┐┌┌┬┐┬─┐┌─┐┬  ┬┌─┐┌─┐┌┬┐
 ║║├┤ │  ├┤ │││ │ ├┬┘├─┤│  │┌─┘├┤  ││
═╩╝└─┘└─┘└─┘┘└┘ ┴ ┴└─┴ ┴┴─┘┴└─┘└─┘─┴┘
╔═╗┌┐┌   ╔═╗┬ ┬┌─┐┬┌┐┌
║ ║│││───║  ├─┤├─┤││││
╚═╝┘└┘   ╚═╝┴ ┴┴ ┴┴┘└┘
╦  ┌─┐┌┬┐┌─┐┌─┐┬─┐  ┬ ┬┬┌┬┐┬ ┬
║  ├┤  │││ ┬├┤ ├┬┘  ││││ │ ├─┤
╩═╝└─┘─┴┘└─┘└─┘┴└─  └┴┘┴ ┴ ┴ ┴
╦  ┌─┐┌─┐┬┌─┌─┐┌┬┐
║  │ ││  ├┴┐├┤  ││
╩═╝└─┘└─┘┴ ┴└─┘─┴┘
╔═╗┌─┐┌─┐┌─┐┌┬┐
╠═╣└─┐└─┐├┤  │
╩ ╩└─┘└─┘└─┘ ┴
╦═╗┌─┐┌─┐┌─┐┬─┐┬  ┬┌─┐
╠╦╝├┤ └─┐├┤ ├┬┘└┐┌┘├┤
╩╚═└─┘└─┘└─┘┴└─ └┘ └─┘
╔═╗┌┬┐┌─┐┌┐ ┬  ┌─┐┌─┐┌─┐┬┌┐┌
╚═╗ │ ├─┤├┴┐│  ├┤ │  │ │││││
╚═╝ ┴ ┴ ┴└─┘┴─┘└─┘└─┘└─┘┴┘└┘

A token that is backed by BillionDollarDapp abstract artwork NFTs.
1 million DOLLARS = 1 BillionDollarDapp pixel NFT (total supply 1024).

1.  One BillionDollarDapp Pixel will always be worth 1 million DOLLARS.
    There are 32x32 (1024) BillionDollarDapp Pixels.  Thus, 1B/1024 ~= 1M.
2.  Each DOLLARS is worth a DAI (and each DAI is worth $1 USD).
3.  Ergo, each BillionDollarDapp Pixel is worth $1 million USD.
4.  Flash minting and arbitrage can be used to maintain the value of DOLLARS
    and the underlying BillionDollarDapp Pixels.

╔═╗╔═╗╔═╗       ╦  ╦┌─┐┬  ┬ ┬┌─┐  ┌─┐┌─┐  ╔═╗╦═╗╔╦╗
╠═╝║╣ ║ ╦  ───  ╚╗╔╝├─┤│  │ │├┤   │ │├┤   ╠═╣╠╦╝ ║
╩  ╚═╝╚═╝        ╚╝ ┴ ┴┴─┘└─┘└─┘  └─┘└    ╩ ╩╩╚═ ╩

Each BillionDollarDapp Pixel is worth 1 million DOLLARS.

1. One BillionDollarDapp Pixel will always be worth
   1 million DOLLARS, and vise versa.

2. If a BillionDollarDapp Pixel < 1 million DOLLARS, then
   buy BDD and sell it for 1 million DOLLARS.

3. If a BillionDollarDapp Pixel > 1 million DOLLARS, then
   buy 1 million DOLLARS, and acquire a BillionDollarDapp Pixel.

4. This keeps prices in line without any need for price oracles.

╔═╗╔═╗╔═╗       ╦  ╦┌─┐┬  ┬ ┬┌─┐  ┌─┐┌─┐  ╔╦╗╔═╗╦
╠═╝║╣ ║ ╦  ───  ╚╗╔╝├─┤│  │ │├┤   │ │├┤    ║║╠═╣║
╩  ╚═╝╚═╝        ╚╝ ┴ ┴┴─┘└─┘└─┘  └─┘└    ═╩╝╩ ╩╩

Each DOLLARS is worth a DAI.

1. One DOLLARS is pegged to one DAI.

2. If a DOLLARS < DAI, then
   buy DOLLARS and sell it for a DAI (if this contract holds any).

3. If a DOLLARS > DAI, then
   use DAI to purchase a DOLLARS.

4. This keeps prices in line without any need for price oracles.

╔═╗╔═╗╔═╗       ╦  ╦┌─┐┬  ┬ ┬┌─┐  ╔═╗┌─┐  ╔═╗┌─┐┌─┐┌┬┐╔═╗┌─┐┌─┐┬ ┬
╠═╝║╣ ║ ╦  ───  ╚╗╔╝├─┤│  │ │├┤   ║ ║├┤   ╠╣ ├─┤└─┐ │ ║  ├─┤└─┐├─┤
╩  ╚═╝╚═╝        ╚╝ ┴ ┴┴─┘└─┘└─┘  ╚═╝└    ╚  ┴ ┴└─┘ ┴ ╚═╝┴ ┴└─┘┴ ┴

Each DOLLARS is worth a 1/($0.25*(1.2**71)) FastCash.

1. One FastCash is Pegged to $104,666.69 / 104,666.69 DOLLARS.

2. If 104,666.69 DOLLARS < 1 FastCash, then
   buy DOLLARS and sell it for a FastCash (if this contract holds any),
   making the difference.

3. If 104,666.69 DOLLARS > 1 FastCash, then
   use FastCash to purchase 104,666.69 DOLLARS.

4. This keeps prices in line without any need for price oracles.

╔═╗┬  ┌─┐┌─┐┬ ┬  ╔╦╗┬┌┐┌┌┬┐┌─┐┌┐ ┬  ┌─┐
╠╣ │  ├─┤└─┐├─┤  ║║║││││ │ ├─┤├┴┐│  ├┤
╚  ┴─┘┴ ┴└─┘┴ ┴  ╩ ╩┴┘└┘ ┴ ┴ ┴└─┘┴─┘└─┘

https://blog.openzeppelin.com/flash-mintable-asset-backed-tokens/

Flash-mintable tokens (FMTs) are ERC20-compliant tokens that allow flash
minting: the ability for anyone to mint an arbitrary number of new tokens into
their account, as long as they also burn the same number of tokens from their
account before the end of the same transaction.

Asset-backed tokens are ERC20-compliant tokens that are 1-to-1 backed and
trustlessly redeemable for some other asset.  In this case either:

1.  1 million DOLLARS are backed by 1 BillionDollarDapp Pixel, or
2.  1 DOLLARS is backed by 1 DAI.

A flash-mintable asset-backed token is exactly what it sounds like: an
ERC20-compliant token that is:

1.  Asset-backed, so everyone can accept them at full face value knowing that
    they can always trustlessly redeem them for the underlying asset.
2.  Flash-mintable, so anyone can mint arbitrarily many unbacked-tokens and
    spend them at full face value, so long as they destroy all the unbacked
    tokens (and therefore restore the backing) before the end of the
    transaction.

In short, everyone can always accept DOLLARS at full face value because
either it is instantly redeemable for a BillionDollarDapp Pixel or DAI
(to the extent this contract holds DAI) whenever they want, or else the EVM will
revert and they’ll have never accepted it in the first place.

As a result, Anyone can print nearly an unlimited number of DOLLARS, and every
contract on  Ethereum can safely accept those tokens (e.g.: as collateral)
and know that each 1 million DOLLARS will be worth exactly 1 BillionDollarDapp
Pixel, or each 1 DOLLAR will be worth 1 DAI (to the extent this contract holds
DAI).  This remains true even during flash mints, when the tokens are not fully
backed by the underlying BillionDollarDapp Pixel or DAI.

╔╦╗┌─┐┬─┐┬┌─┌─┐┌┬┐┌─┐┬  ┌─┐┌─┐┌─┐
║║║├─┤├┬┘├┴┐├┤  │ ├─┘│  ├─┤│  ├┤
╩ ╩┴ ┴┴└─┴ ┴└─┘ ┴ ┴  ┴─┘┴ ┴└─┘└─┘

DOLLARS are a utility token that BillionDollarDapp Pixel owners can use to
exchange BillionDollarDapp Pixels.

███╗   ██╗███████╗ █████╗     ██████╗ ██╗   ██╗ ██████╗ ██████╗
████╗  ██║██╔════╝██╔══██╗    ██╔══██╗╚██╗ ██╔╝██╔═══██╗██╔══██╗
██╔██╗ ██║█████╗  ███████║    ██║  ██║ ╚████╔╝ ██║   ██║██████╔╝
██║╚██╗██║██╔══╝  ██╔══██║    ██║  ██║  ╚██╔╝  ██║   ██║██╔══██╗
██║ ╚████║██║     ██║  ██║    ██████╔╝   ██║   ╚██████╔╝██║  ██║
╚═╝  ╚═══╝╚═╝     ╚═╝  ╚═╝    ╚═════╝    ╚═╝    ╚═════╝ ╚═╝  ╚═╝
╔╗╔╔═╗╔╦╗  ╔═╗╦╔╗╔╔═╗╔╗╔╔═╗╦╔═╗╦    ╔═╗╔╦╗╦  ╦╦╔═╗╔═╗
║║║║ ║ ║   ╠╣ ║║║║╠═╣║║║║  ║╠═╣║    ╠═╣ ║║╚╗╔╝║╚═╗║╣
╝╚╝╚═╝ ╩   ╚  ╩╝╚╝╩ ╩╝╚╝╚═╝╩╩ ╩╩═╝  ╩ ╩═╩╝ ╚╝ ╩╚═╝╚═╝
╔╦╗╔═╗  ╦ ╦╔═╗╦ ╦╦═╗  ╔═╗╦ ╦╔╗╔  ╦═╗╔═╗╔═╗╔═╗╔═╗╦═╗╔═╗╦ ╦
 ║║║ ║  ╚╦╝║ ║║ ║╠╦╝  ║ ║║║║║║║  ╠╦╝║╣ ╚═╗║╣ ╠═╣╠╦╝║  ╠═╣
═╩╝╚═╝   ╩ ╚═╝╚═╝╩╚═  ╚═╝╚╩╝╝╚╝  ╩╚═╚═╝╚═╝╚═╝╩ ╩╩╚═╚═╝╩ ╩
NOTHING IN THIS COMMENT IS FINANCIAL ADVISE
DO YOUR OWN RESEARCH TO VERIFY ANY STATEMENTS OR CLAIMS
READ THE CONTRACT (WHICH HAS NOT BEEN AUDITED) BEFORE INTERACTING
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20FlashMint.sol";
import "./SafeERC20.sol";

import "./IERC721.sol";

import "./ReentrancyGuard.sol";

contract Dollars is ERC20, ERC20Burnable, Ownable, ERC20FlashMint, ReentrancyGuard {
    using Address for address payable;

    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 public constant FCM = IERC20(0xcA5228D1fe52D22db85E02CA305cddD9E573D752);
    // The number of Dollars Per 1 FastCashMoney is: (($0.25 * (1.2 ** 71)))
    uint256 public DollarsPerFCM = 10466668708; // Divide this by 100k to get proper decimal

    IERC721 public constant NFT = IERC721(0xDE41fD6dfa8194A1B32A91cB1313402007A31173);
    uint256 public DollarsPerNFT = 1000000000000000000000000; // 1 million DOLLARS per NFT

    mapping (address => uint256) public stakedErc20Tokens;
    mapping (uint256 => bool) public isNFTStakedByTokenId;
    uint256 public stakedNFTs = 0;

    // @dev EVENTS
    /* ╔═╗┬  ┬┌─┐┌┐┌┌┬┐┌─┐
       ║╣ └┐┌┘├┤ │││ │ └─┐
       ╚═╝ └┘ └─┘┘└┘ ┴ └─┘ */

    event PaymentReceived(address indexed from, uint256 amount);

    event NFTConvertedToDollars(address indexed from, uint256 indexed tokenId);
    event DollarsConvertedToNFT(address indexed from, uint256 indexed tokenId);

    event DAIConvertedToDollars(address indexed from, uint256 indexed amount);
    event DollarsConvertedToDAI(address indexed from, uint256 indexed amount);

    event FCMConvertedToDollars(address indexed from, uint256 indexed amountDollars, uint256 indexed amountFCM);
    event DollarsConvertedToFCM(address indexed from, uint256 indexed amountDollars, uint256 indexed amountFCM);

    event PaymentReleased(address indexed to, uint256 amount);
    event PaymentReleasedErc20(IERC20 indexed token, address indexed to, uint256 amount);

    // @dev CONSTRUCTOR
    /* ╔═╗┌─┐┌┐┌┌─┐┌┬┐┬─┐┬ ┬┌─┐┌┬┐┌─┐┬─┐
       ║  │ ││││└─┐ │ ├┬┘│ ││   │ │ │├┬┘
       ╚═╝└─┘┘└┘└─┘ ┴ ┴└─└─┘└─┘ ┴ └─┘┴└─ */

    constructor() ERC20("Dollars", "DOLLARS") {}

    // @dev INTERNAL
    /* ╦┌┐┌┌┬┐┌─┐┬─┐┌┐┌┌─┐┬  
       ║│││ │ ├┤ ├┬┘│││├─┤│  
       ╩┘└┘ ┴ └─┘┴└─┘└┘┴ ┴┴─┘ */

    function mint(address _to, uint256 _amount) internal {
        _mint(_to, _amount);
    }

    // @dev DAI FUNCTIONS
    /* ╔╦╗┌─┐┬┌─┌─┐┬─┐╔╦╗┌─┐┌─┐  ╔╦╗╔═╗╦
       ║║║├─┤├┴┐├┤ ├┬┘ ║║├─┤│ │   ║║╠═╣║
       ╩ ╩┴ ┴┴ ┴└─┘┴└─═╩╝┴ ┴└─┘  ═╩╝╩ ╩╩ */

    // When you use DAI to buy DOLLARS, ...
    //    you need to make sure ...
    // On the DAI contract execute approve transaction:
    //    from: your account
    //    spender: [this contract address]
    //    amount: 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    function buyDollarsWithDAI(uint256 _amount) external nonReentrant() {
        require(DAI.transferFrom(msg.sender, address(this), _amount), "DAI Buy failed.");
        stakedErc20Tokens[address(DAI)] += _amount;
        _mint(msg.sender, _amount);
        emit DAIConvertedToDollars(msg.sender, _amount);
    }

    // When you sell DOLLARS, ...
    //    you need to make sure the DOLLARS contract is authorized.
    // On the DOLLARS contract execute approve transaction:
    //    from: your account
    //    spender: your account
    //    amount: 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    function sellDollarsForDAI(uint256 _amount) external nonReentrant() {
        require(balanceOf(msg.sender) >= _amount, "Insufficent DOLLAR balance.");
        require(DAI.transferFrom(address(this), msg.sender, _amount), "DAI sale failed.");
        stakedErc20Tokens[address(DAI)] -= _amount;
        burnFrom(msg.sender, _amount);
        emit DollarsConvertedToDAI(msg.sender, _amount);
    }

    // @dev FASTCASH FUNCTIONS
    /* ╔═╗┌─┐┌─┐┌┬┐╔═╗┌─┐┌─┐┬ ┬
       ╠╣ ├─┤└─┐ │ ║  ├─┤└─┐├─┤
       ╚  ┴ ┴└─┘ ┴ ╚═╝┴ ┴└─┘┴ ┴ */

    // When you use FastCashMoney to buy DOLLARS, ...
    //    you need to make sure ...
    // On the FastCashMoney contract execute approve transaction:
    //    from: your account
    //    spender: [this contract address]
    //    amount: 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    function buyDollarsWithFCM(uint256 _amountFCM) external nonReentrant() {
        // the FCM transferFrom function does not return true on success.
        FCM.transferFrom(msg.sender, address(this), _amountFCM);
        stakedErc20Tokens[address(FCM)] += _amountFCM;
        _mint(msg.sender, _amountFCM * DollarsPerFCM / 100000);
        emit FCMConvertedToDollars(msg.sender, _amountFCM * DollarsPerFCM / 100000, _amountFCM);
    }

    // When you sell DOLLARS, ...
    //    you need to make sure the DOLLARS contract is authorized.
    // On the DOLLARS contract execute approve transaction:
    //    from: your account
    //    spender: your account
    //    amount: 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    function sellDollarsForFCM(uint256 _amountDOLLARS) external nonReentrant() {
        require(balanceOf(msg.sender) >= _amountDOLLARS, "Insufficent DOLLAR balance.");
        // the FCM transferFrom function does not return true on success.
        uint256 _amountFCM = _amountDOLLARS * 100000 / DollarsPerFCM;
        FCM.approve(address(this), _amountFCM);
        FCM.transferFrom(address(this), msg.sender, _amountFCM);
        stakedErc20Tokens[address(FCM)] -= _amountFCM;
        burnFrom(msg.sender, _amountDOLLARS);
        emit DollarsConvertedToFCM(msg.sender, _amountDOLLARS, _amountFCM);
    }
    
    // @dev INDIVIDUAL NFT/COIN SWAP
    /* ╔╗ ┬┬  ┬  ┬┌─┐┌┐┌╔╦╗┌─┐┬  ┬  ┌─┐┬─┐╔╦╗┌─┐┌─┐┌─┐
       ╠╩╗││  │  ││ ││││ ║║│ ││  │  ├─┤├┬┘ ║║├─┤├─┘├─┘
       ╚═╝┴┴─┘┴─┘┴└─┘┘└┘═╩╝└─┘┴─┘┴─┘┴ ┴┴└─═╩╝┴ ┴┴  ┴  
       ╦┌┐┌┌┬┐┬┬  ┬┬┌┬┐┬ ┬┌─┐┬                        
       ║│││ │││└┐┌┘│ │││ │├─┤│                        
       ╩┘└┘─┴┘┴ └┘ ┴─┴┘└─┘┴ ┴┴─┘                      
       ╔═╗┬─┐ ┬┌─┐┬                                   
       ╠═╝│┌┴┬┘├┤ │                                   
       ╩  ┴┴ └─└─┘┴─┘                                 
       ╔═╗┬ ┬┌─┐┌─┐                                   
       ╚═╗│││├─┤├─┘                                   
       ╚═╝└┴┘┴ ┴┴ */

    // When you use a NFT to buy DOLLARS, ...
    //    you need to make sure ...
    // On the BillionDollarDapp contract execute setApprovalForAll:
    //    from: your account
    //    operator: [this contract address]
    //    approved: true
    function buyDollarsWithPixel(uint256 _tokenId) public nonReentrant() {
        NFT.transferFrom(msg.sender, address(this), _tokenId);
        isNFTStakedByTokenId[_tokenId] = true;
        stakedNFTs++;
        _mint(msg.sender, DollarsPerNFT);
        emit NFTConvertedToDollars(msg.sender, _tokenId);
    }

    // When you sell DOLLARS, ...
    //    you need to make sure the DOLLARS contract is approved.
    // On the DOLLARS contract execute approve transaction:
    // from: your account
    // spender: your account
    // amount: 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    function sellDollarsForPixel(uint256 _tokenId) public nonReentrant() {
        require(balanceOf(msg.sender) >= DollarsPerNFT, "Insufficent DOLLAR balance.");
        NFT.transferFrom(address(this), msg.sender, _tokenId);
        isNFTStakedByTokenId[_tokenId] = false;
        stakedNFTs--;
        burnFrom(msg.sender, DollarsPerNFT);
        emit DollarsConvertedToNFT(msg.sender, _tokenId);
    }

    // @dev BULK NFT/COIN SWAP
    /* ╔╗ ┬┬  ┬  ┬┌─┐┌┐┌╔╦╗┌─┐┬  ┬  ┌─┐┬─┐╔╦╗┌─┐┌─┐┌─┐
       ╠╩╗││  │  ││ ││││ ║║│ ││  │  ├─┤├┬┘ ║║├─┤├─┘├─┘
       ╚═╝┴┴─┘┴─┘┴└─┘┘└┘═╩╝└─┘┴─┘┴─┘┴ ┴┴└─═╩╝┴ ┴┴  ┴  
       ╔╗ ┬ ┬┬  ┬┌─                                   
       ╠╩╗│ ││  ├┴┐                                   
       ╚═╝└─┘┴─┘┴ ┴                                   
       ╔═╗┬─┐ ┬┌─┐┬                                   
       ╠═╝│┌┴┬┘├┤ │                                   
       ╩  ┴┴ └─└─┘┴─┘                                 
       ╔═╗┬ ┬┌─┐┌─┐                                   
       ╚═╗│││├─┤├─┘                                   
       ╚═╝└┴┘┴ ┴┴ */

    function buyDollarsWithPixels(uint256[] memory _tokenIds) public nonReentrant() {
        uint256 _reward = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            NFT.transferFrom(msg.sender, address(this), _tokenIds[i]);
            isNFTStakedByTokenId[_tokenIds[i]] = true;
            stakedNFTs++;
            _reward += DollarsPerNFT;
            emit NFTConvertedToDollars(msg.sender, _tokenIds[i]);
        }
        _mint(msg.sender, _reward);
    }

    function sellDollarsForPixels(uint256[] memory _tokenIds) public nonReentrant() {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(balanceOf(msg.sender) >= DollarsPerNFT, "Insufficent DOLLAR balance.");
            NFT.transferFrom(address(this), msg.sender, _tokenIds[i]);
            isNFTStakedByTokenId[_tokenIds[i]] = false;
            stakedNFTs--;
            burnFrom(msg.sender, DollarsPerNFT);
            emit DollarsConvertedToNFT(msg.sender, _tokenIds[i]);
        }
    }

    // @dev FINANCIAL FUNCTIONS
    /* ╔═╗┬┌┐┌┌─┐┌┐┌┌─┐┬┌─┐┬    ╔═╗┬ ┬┌┐┌┌─┐┌┬┐┬┌─┐┌┐┌┌─┐
       ╠╣ ││││├─┤││││  │├─┤│    ╠╣ │ │││││   │ ││ ││││└─┐
       ╚  ┴┘└┘┴ ┴┘└┘└─┘┴┴ ┴┴─┘  ╚  └─┘┘└┘└─┘ ┴ ┴└─┘┘└┘└─┘ */

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    // @dev Triggers payout of all ETH held by contract.
    function withdraw() external nonReentrant() onlyOwner() {
        uint256 _startingBalance = address(this).balance;
        payable(this.owner()).sendValue(_startingBalance);
        emit PaymentReleased(this.owner(), _startingBalance);
    }

    // @dev Triggers payout of all ERC20 held by contract.
    function withdrawErc20(IERC20 token, uint256 _amount) public virtual nonReentrant() onlyOwner() {
        // checks effects
        require(token.balanceOf(address(this)) > 0, "No tokens.");
        require(_amount <= (token.balanceOf(address(this)) - stakedErc20Tokens[address(token)]));

        // interactions
        SafeERC20.safeTransfer(token, this.owner(), _amount);
        emit PaymentReleasedErc20(token, this.owner(), _amount);
    }
}