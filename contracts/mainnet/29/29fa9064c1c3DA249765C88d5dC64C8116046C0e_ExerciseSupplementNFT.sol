// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./EnumerableSet.sol";
import "./ERC721Burnable.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";

contract ExerciseSupplementNFT is ERC721, Ownable, ERC721Burnable{
    using Strings for uint256;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct NftSpecialConditionInfo {
        uint256 targetStepPerDay;
        uint256 challengeDuration;
        uint256 amountDepositMatic;
        uint256 amountDepositTTJP;
        uint256 amountDepositJPYC;
        uint256 dividendSuccess;
    }    

    Counters.Counter private _tokenIdCounter;
    string public baseURI;
    string public baseExtension = ".json";
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private admins;
    EnumerableSet.AddressSet private listNftAddress;
    EnumerableSet.AddressSet private listERC20Address;
    EnumerableSet.AddressSet private listSpecialNftAddress;
    address public donationWalletAddress; 
    mapping(address => bool) public typeNfts;
    NftSpecialConditionInfo public listNftSpecialConditionInfo;
    mapping(address => uint256) private typeTokenErc20;

    modifier onlyAdmin() {
        require(admins.contains(_msgSender()), "NOT ADMIN");
        _;
    }

    constructor(
        string memory _initBaseURI
    ) ERC721("ExerciseSupplementNFT", "ESPLNFT") {
        setBaseURI(_initBaseURI);
        admins.add(msg.sender);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function safeMint(address to) public payable {
        require(_msgSender().code.length > 0 || admins.contains(_msgSender()), 
            "Address can't mint NFT"
        );
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function nextTokenIdToMint() public view returns(uint256) {
        return _tokenIdCounter.current();
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

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function updateNftListAddress(address _nftAddress, bool _flag, bool _isTypeErc721) external onlyAdmin {
        require(_nftAddress != address(0), "INVALID NFT ADDRESS");
        if (_flag) {
            listNftAddress.add(_nftAddress);
        } else {
            listNftAddress.remove(_nftAddress);
        }
        typeNfts[_nftAddress] = _isTypeErc721;
    }
    
    function updateListERC20Address(address _erc20Address, bool _flag) external onlyAdmin {
        require(_erc20Address != address(0), "INVALID NFT ADDRESS");
        if (_flag) {
            listERC20Address.add(_erc20Address);
        } else {
            listERC20Address.remove(_erc20Address);
        }
        if(compareStrings(ERC721(_erc20Address).symbol(), "TTJP")) {
            typeTokenErc20[_erc20Address] = 1;
        } else {
            if(compareStrings(ERC721(_erc20Address).symbol(), "JPYC")) {
                typeTokenErc20[_erc20Address] = 2;
            } else {
                typeTokenErc20[_erc20Address] = 3;
            }
        }
    }

    function updateSpecialNftAddress(
        address _nftAddress, 
        bool _flag
    ) external onlyAdmin {
        require(_nftAddress != address(0), "INVALID NFT ADDRESS");
        if (_flag) {
            listSpecialNftAddress.add(_nftAddress);
        } else {
            listSpecialNftAddress.remove(_nftAddress);
        } 
    }

    function updateAdmin(address _adminAddr, bool _flag) external onlyAdmin {
        require(_adminAddr != address(0), "INVALID ADDRESS");
        if (_flag) {
            admins.add(_adminAddr);
        } else {
            admins.remove(_adminAddr);
        }
    }

    function updateDonationWalletAddress(address _donationWalletAddress) external onlyAdmin {
        require(_donationWalletAddress != address(0), "INVALID ADDRESS");
        donationWalletAddress = _donationWalletAddress;
    }

    function getTypeTokenErc20(address _erc20Address) public view returns(uint256) {
        return typeTokenErc20[_erc20Address];
    }

    function updateSpecialConditionInfo(
        uint256 targetStepPerDay, // 6000
        uint256 challengeDuration, // 7
        uint256 amountDepositMatic, // if 10 MATIC you input 10 * 10^18
        uint256 amountDepositTTJP, // if 1000 TTJP you input 1000 * 10^18
        uint256 amountDepositJPYC, // if 1000 JPYC you input 1000 * 10^18
        uint256 dividendSuccess // 98 => set dividendSuccess or 0 => not set dividendSuccess
    ) external onlyAdmin{
        listNftSpecialConditionInfo = NftSpecialConditionInfo(
            targetStepPerDay,
            challengeDuration,
            amountDepositMatic,
            amountDepositTTJP,
            amountDepositJPYC,
            dividendSuccess
        );
    }
    
    function safeMintSpecialNft(
        uint256 _goal,
        uint256 _duration, 
        address _createByToken, 
        uint256 _totalReward,
        uint256 _awardReceiversPercent,
        address _awardReceivers,
        address _challenger
    ) public returns(address, uint256){
        require(_msgSender().code.length > 0 || admins.contains(_msgSender()), 
            "Address can't mint NFT"
        );
        address curentAddressNftUse;
        uint256 indexNftAfterMint;
        if(
            _goal >= listNftSpecialConditionInfo.targetStepPerDay &&  
            _duration >= listNftSpecialConditionInfo.challengeDuration && 
            _duration >= _duration.sub(_duration.div(7)) &&
            checkAmountDepositCondition(_createByToken, _totalReward)
        ) {
            if(
                _awardReceiversPercent == listNftSpecialConditionInfo.dividendSuccess &&
                _awardReceivers == donationWalletAddress
            ) {
                TransferHelper.safeMintNFT(
                    listSpecialNftAddress.at(1),
                    _challenger
                );
                curentAddressNftUse = listSpecialNftAddress.at(1);
                indexNftAfterMint = ExerciseSupplementNFT(listSpecialNftAddress.at(1)).nextTokenIdToMint();
            } else {
                TransferHelper.safeMintNFT(
                    listSpecialNftAddress.at(0),
                    _challenger
                );
                curentAddressNftUse = listSpecialNftAddress.at(0);
                indexNftAfterMint = ExerciseSupplementNFT(listSpecialNftAddress.at(0)).nextTokenIdToMint();
            }
        } else {
            TransferHelper.safeMintNFT(
                listNftAddress.at(0),
                _challenger
            );
            curentAddressNftUse = listNftAddress.at(0);
            indexNftAfterMint = ExerciseSupplementNFT(listNftAddress.at(0)).nextTokenIdToMint();
        }
        
        return (curentAddressNftUse, indexNftAfterMint);
    }

    function checkAmountDepositCondition(address _createByToken, uint256 _totalReward) private view returns(bool) {
        if(_createByToken == address(0) && _totalReward >= listNftSpecialConditionInfo.amountDepositMatic) {
            return true;
        }

        if(_createByToken == address(0)) {
            return false;
        }

        if(
            typeTokenErc20[_createByToken] == 1 && _totalReward >= listNftSpecialConditionInfo.amountDepositTTJP || 
            typeTokenErc20[_createByToken] == 2 && _totalReward >= listNftSpecialConditionInfo.amountDepositJPYC
        ) {
            return true;
        }

        return false;
    }

    function getAdmins() external view returns (address[] memory) {
        return admins.values();
    }
 
    function getNftListAddress() external view returns (address[] memory) {
        return listNftAddress.values();
    }

    function getErc20ListAddress() external view returns (address[] memory) {
        return listERC20Address.values();
    }

    function getSpecialNftAddress() external view returns (address[] memory) {
        return listSpecialNftAddress.values();
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}