pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC721.sol";
import "./Clones.sol";

contract NFTStoreHouse is Ownable, Pausable {
    address public constant eth = address(0);
    
    uint public lockedNFTCount = 0;
    uint public currentNFTIndex = 1;
    mapping(uint => address) public indexToFNFTAddress;
    mapping(address => uint) public fnftAddressToIndex;
    
    address public immutable governanceSettings;
    address public fnftBlueprint;
    
    event LockNFT(address indexed nftContractAddress, uint tokenID, address fnftContractAddress, uint fnftIndex);
    event StartAuction(address indexed fnftContractAddress, address user, uint price);
    event RedeemWithAllSupply(address indexed fnftContractAddress, address user);
    event AuctionEnd(address indexed fnftContractAddress, address user, uint price);
    event DirectBuyout(address indexed fnftContractAddress, address approver, address buyer, uint price);
    
    constructor(address _governanceSettings, address _fnftBlueprint) {
        governanceSettings = _governanceSettings;
        fnftBlueprint = _fnftBlueprint;
    }
    
    function pause() public onlyOwner {
        super._pause();
    }
    
    function unpause() public onlyOwner {
        super._unpause();
    }
    
    function _lockNFT(
        string memory _name,
        string memory _symbol,
        uint _totalSupply,
        uint _reservePrice,
        address _currency,
        address _lockedNFTContract,
        uint _tokenID,
        uint _requireVoterTurnoutRate,
        uint _requireShareholdingRatio,
        bool _allowDirectBuyout
    ) private whenNotPaused returns (uint) {
        bytes memory implementationCalldata = abi.encodeWithSignature(
            "initialize(address,string,string,uint256,uint256,address,address,uint256,uint256,address,uint256,bool)",
            governanceSettings,
            _name,
            _symbol,
            _totalSupply,
            _reservePrice,
            _currency,
            _lockedNFTContract,
            _tokenID,
            _requireVoterTurnoutRate,
            msg.sender,
            _requireShareholdingRatio,
            _allowDirectBuyout
        );

        address fnftContractAddress = Clones.clone(fnftBlueprint);
        (bool ok,) = fnftContractAddress.call(implementationCalldata); //trans data to the address
        require(ok);

        IERC721(_lockedNFTContract).transferFrom(msg.sender, fnftContractAddress, _tokenID);
        indexToFNFTAddress[currentNFTIndex] = fnftContractAddress;
        fnftAddressToIndex[fnftContractAddress] = currentNFTIndex;
        emit LockNFT(_lockedNFTContract, _tokenID, fnftContractAddress, currentNFTIndex);
        
        currentNFTIndex++;
        lockedNFTCount++;
        return currentNFTIndex - 1;
    }
    
    function lockNFTUsingETHForBuyout(
        string memory _name,
        string memory _symbol,
        uint _totalSupply,
        uint _reservePrice,
        address _lockedNFTContract,
        uint _tokenID,
        uint _requireVoterTurnoutRate,
        uint _requireShareholdingRatio,
        bool _allowDirectBuyout
    ) public {
        _lockNFT(
            _name,
            _symbol,
            _totalSupply,
            _reservePrice,
            eth,
            _lockedNFTContract,
            _tokenID,
            _requireVoterTurnoutRate,
            _requireShareholdingRatio,
            _allowDirectBuyout
        );
    }
    
    function lockNFTUsingOtherCurrencyForBuyout(
        string memory _name,
        string memory _symbol,
        uint _totalSupply,
        uint _reservePrice,
        address _currency,
        address _lockedNFTContract,
        uint _tokenID,
        uint _requireVoterTurnoutRate,
        uint _requireShareholdingRatio,
        bool _allowDirectBuyout
    ) public {
        _lockNFT(
            _name,
            _symbol,
            _totalSupply,
            _reservePrice,
            _currency,
            _lockedNFTContract,
            _tokenID,
            _requireVoterTurnoutRate,
            _requireShareholdingRatio,
            _allowDirectBuyout
        );
    }

    function emitStartAuctionEvent(address _user, uint _price) external {
        // require(false, "test");
        require(fnftAddressToIndex[msg.sender] > 0, "inputted contract not in database!");
        emit StartAuction(msg.sender, _user, _price);
    }
    
    function emitAuctionEndEvent(address _user, uint _price) external {
        require(fnftAddressToIndex[msg.sender] >= 1);
        emit AuctionEnd(msg.sender, _user, _price);
    }
    
    function emitRedeemWithAllSupplyEvent(address _user) external {
        require(fnftAddressToIndex[msg.sender] >= 1);
        emit RedeemWithAllSupply(msg.sender, _user);
    }
    
    function emitDirectBuyoutEvent(address _approver, address _buyer, uint _price) external {
        require(fnftAddressToIndex[msg.sender] >= 1);
        emit DirectBuyout(msg.sender, _approver, _buyer, _price);
    }

    function readFNFTAddressFromIndex (uint _index) external view returns (address){
        return indexToFNFTAddress[_index];
    }

    function readFNFTIndexFromAddress (address _address) external view returns (uint){
        return fnftAddressToIndex[_address];
    }

    function kill() external {
        selfdestruct(payable(eth));
    }

    function updateFNFTBlueprint(address _newAddress) external onlyOwner {
        fnftBlueprint = _newAddress;
    }
}