pragma solidity ^0.5.0;

import "./CustomERC721Metadata.sol";
import "./Strings.sol";


interface Randomizer {
   function returnValue() external view returns(bytes32);
}

contract Baeowp is CustomERC721Metadata {
    using SafeMath for uint256;
    event Mint(
        address indexed _to,
        uint256 indexed _tokenId,
        uint256 indexed _projectId
    );

    Randomizer public randomizerContract;
    
    struct Project {
        string projectJson;
        string projectAdditionalJson;
        string projectResourceJson;
        string scriptJSON;
        mapping(uint256 => string) scripts;
        uint scriptCount;
        string projectBaseURI;
        string resourceBaseIpfsURI;
        uint256 publications;
        uint256 maxPublications;
        string resourceIpfsHash;
        bool active;
        bool locked;
        address payable artistAddress;
        address payable additionalPayee;   
        uint256 thirdAddressPercentage;
        uint256 secondMarketRoyalty;     
        uint256 pricePerTokenInWei;
    }
    
    address public admin;
    address payable public baeowpAddress;
    uint256 public baeowpPercentage = 10;

    uint256 constant TEN_THOUSAND = 10_000;
    uint256 public nextProjectId;
    mapping(uint256 => Project) projects;
    mapping(uint256 => uint256) public tokenIdToProjectId;
    mapping(uint256 => uint256[]) internal projectIdToTokenIds;
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(bytes32 => uint256) public hashToTokenId;

    function _onlyValidTokenId(uint256 _tokenId) private view {
        require(_exists(_tokenId), "Token ID does not exist");
    }
    function _onlyUnlocked(uint256 _projectId) private view {
        require(!projects[_projectId].locked, "Only if unlocked");
    }
    function _onlyArtist(uint256 _projectId) private view {
        require(msg.sender == projects[_projectId].artistAddress, "Only artist");
    }
    function _onlyAdmin() private view {
        require(msg.sender == admin, "Only admin");
    }
    modifier onlyValidTokenId(uint256 _tokenId) {
        _onlyValidTokenId(_tokenId);
        _;
    }
    modifier onlyUnlocked(uint256 _projectId) {
        _onlyUnlocked(_projectId);
        _;
    }
    modifier onlyArtist(uint256 _projectId) {
        _onlyArtist(_projectId);
        _;
    }
    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    constructor(string memory _tokenName, string memory _tokenSymbol, address _randomizerContract) CustomERC721Metadata(_tokenName, _tokenSymbol) public {
        admin = msg.sender;
        baeowpAddress = msg.sender;
        randomizerContract = Randomizer(_randomizerContract);

    }

    function purchase(uint256 _projectId) public payable returns (uint256 _tokenId) {
        return purchaseTo(msg.sender, _projectId);
    }

    function purchaseTo(address _to, uint256 _projectId) public payable returns (uint256 _tokenId) {
        require(msg.value >= projects[_projectId].pricePerTokenInWei, "Must send at least pricePerTokenInWei");
        require(projects[_projectId].publications.add(1) <= projects[_projectId].maxPublications, "Must not exceed max publications");
        require(projects[_projectId].active || msg.sender == projects[_projectId].artistAddress, "Project must exist and be active");

        uint256 tokenId = _mintToken(_to, _projectId);

        _shareMint(_projectId);

        return tokenId;
    }

    function _mintToken(address _to, uint256 _projectId) internal returns (uint256 _tokenId) {

        uint256 tokenIdToBe = (_projectId * TEN_THOUSAND) + projects[_projectId].publications;

        projects[_projectId].publications = projects[_projectId].publications.add(1);

        bytes32 hash = keccak256(abi.encodePacked(projects[_projectId].publications, block.number, blockhash(block.number - 1), msg.sender, randomizerContract));
        tokenIdToHash[tokenIdToBe]=hash;
        hashToTokenId[hash] = tokenIdToBe;

        _mint(_to, tokenIdToBe);

        tokenIdToProjectId[tokenIdToBe] = _projectId;
        projectIdToTokenIds[_projectId].push(tokenIdToBe);

        emit Mint(_to, tokenIdToBe, _projectId);

        return tokenIdToBe;
    }

    function _shareMint(uint256 _projectId) internal {
        if (msg.value > 0) {

            uint256 pricePerTokenInWei = projects[_projectId].pricePerTokenInWei;
            uint256 refund = msg.value.sub(projects[_projectId].pricePerTokenInWei);

            if (refund > 0) {
                msg.sender.transfer(refund);
            }

            uint256 foundationAmount = pricePerTokenInWei.div(100).mul(baeowpPercentage);
            if (foundationAmount > 0) {
                baeowpAddress.transfer(foundationAmount);
            }

            uint256 projectFunds = pricePerTokenInWei.sub(foundationAmount);

            uint256 additionalPayeeAmount;
            if (projects[_projectId].thirdAddressPercentage > 0) {
                additionalPayeeAmount = projectFunds.div(100).mul(projects[_projectId].thirdAddressPercentage);
                if (additionalPayeeAmount > 0) {
                    projects[_projectId].additionalPayee.transfer(additionalPayeeAmount);
                }
            }

            uint256 creatorFunds = projectFunds.sub(additionalPayeeAmount);
            if (creatorFunds > 0) {
                projects[_projectId].artistAddress.transfer(creatorFunds);
            }
        }
    }

    function updateBaeowpAddress(address payable _baeowpAddress) public onlyAdmin {
        baeowpAddress = _baeowpAddress;
    }

    function updateBaeowpPercentage(uint256 _baeowpPercentage) public onlyAdmin {
        require(_baeowpPercentage <= 25, "max 25");
        baeowpPercentage = _baeowpPercentage;
    }

    function doLockProject(uint256 _projectId) public onlyArtist(_projectId)  onlyUnlocked(_projectId) {
        projects[_projectId].locked = true;
    }

    function updateRandomizerAddress(uint256 _projectId, address _randomizerAddress) public onlyArtist(_projectId) {
        randomizerContract = Randomizer(_randomizerAddress);
    }

    function toggleProjectIsActive(uint256 _projectId) public onlyArtist(_projectId)  {
        projects[_projectId].active = !projects[_projectId].active;
    }

    function updateProjectArtistAddress(uint256 _projectId, address payable _artistAddress) public onlyArtist(_projectId) {
        projects[_projectId].artistAddress = _artistAddress;
    }

    function addProject(address payable _artistAddress, uint256 _pricePerTokenInWei) public onlyAdmin {

        uint256 projectId = nextProjectId;
        projects[projectId].artistAddress = _artistAddress;
        projects[projectId].pricePerTokenInWei = _pricePerTokenInWei;
        projects[projectId].maxPublications = TEN_THOUSAND;
        nextProjectId = nextProjectId.add(1);
    }
   
    function updateProjectPricePerTokenInWei(uint256 _projectId, uint256 _pricePerTokenInWei) onlyArtist(_projectId) public {
        projects[_projectId].pricePerTokenInWei = _pricePerTokenInWei;
    }

    
    function updateProjectAdditionalPayeeInfo(uint256 _projectId, address payable _additionalPayee, uint256 _thirdAddressPercentage) onlyArtist(_projectId) public {
        require(_thirdAddressPercentage <= 100, "max 100");
        projects[_projectId].additionalPayee = _additionalPayee;
        projects[_projectId].thirdAddressPercentage = _thirdAddressPercentage;
    }

    function updateProjectSecondaryMarketRoyaltyPercentage(uint256 _projectId, uint256 _secondMarketRoyalty) onlyArtist(_projectId) public {
        require(_secondMarketRoyalty <= 100, "max 100");
        projects[_projectId].secondMarketRoyalty = _secondMarketRoyalty;
    }

    function updateProjectJson(uint256 _projectId, string memory _projectJSON) onlyUnlocked(_projectId) onlyArtist(_projectId) public {
        projects[_projectId].projectJson = _projectJSON;
    }
    function updateProjectAdditionalJson(uint256 _projectId, string memory _projectAdditionalJson) onlyArtist(_projectId) public {
        projects[_projectId].projectAdditionalJson = _projectAdditionalJson;
    }

    function updateProjectMaxPublications(uint256 _projectId, uint256 _maxPublications) onlyUnlocked(_projectId) onlyArtist(_projectId) public {
        require(_maxPublications > projects[_projectId].publications, "You must set max publications greater than current publications");
        require(_maxPublications <= TEN_THOUSAND,  "Cannot exceed 10,000");
        projects[_projectId].maxPublications = _maxPublications;
    }

    function addProjectScript(uint256 _projectId, string memory _script) onlyUnlocked(_projectId) onlyArtist(_projectId) public {
        projects[_projectId].scripts[projects[_projectId].scriptCount] = _script;
        projects[_projectId].scriptCount = projects[_projectId].scriptCount.add(1);
    }

    function updateProjectScript(uint256 _projectId, uint256 _scriptId, string memory _script) onlyUnlocked(_projectId) onlyArtist(_projectId) public {
        require(_scriptId < projects[_projectId].scriptCount, "scriptId out of range");
        projects[_projectId].scripts[_scriptId] = _script;
    }

    function removeProjectLastScript(uint256 _projectId) onlyUnlocked(_projectId) onlyArtist(_projectId) public {
        require(projects[_projectId].scriptCount > 0, "there are no scripts to remove");
        delete projects[_projectId].scripts[projects[_projectId].scriptCount - 1];
        projects[_projectId].scriptCount = projects[_projectId].scriptCount.sub(1);
    }

    function updateProjectScriptJSON(uint256 _projectId, string memory _projectScriptJSON) onlyUnlocked(_projectId) onlyArtist(_projectId) public {
        projects[_projectId].scriptJSON = _projectScriptJSON;
    }

    function updateProjectResourceJSON(uint256 _projectId, string memory _projectResourceJson) onlyUnlocked(_projectId) onlyArtist(_projectId) public {
        projects[_projectId].projectResourceJson = _projectResourceJson;
    }

    function updateProjectResourceIpfsHash(uint256 _projectId, string memory _resourceIpfsHash) onlyUnlocked(_projectId) onlyArtist(_projectId) public {
        projects[_projectId].resourceIpfsHash = _resourceIpfsHash;
    }

    function updateProjectBaseURI(uint256 _projectId, string memory _newBaseURI) onlyArtist(_projectId) public {
        projects[_projectId].projectBaseURI = _newBaseURI;
    }

    function updateResourceBaseIpfsURI(uint256 _projectId, string memory _resourceBaseIpfsURI) onlyArtist(_projectId) public {
        projects[_projectId].resourceBaseIpfsURI = _resourceBaseIpfsURI;
    }

    function projectDetails(uint256 _projectId) view public returns (string memory projectJson, string memory projectAdditionalJson, string memory projectResourceJson) {
        projectJson = projects[_projectId].projectJson;
        projectAdditionalJson = projects[_projectId].projectAdditionalJson;
        projectResourceJson = projects[_projectId].projectResourceJson;
    }


    function projectTokenInfo(uint256 _projectId) view public returns (address artistAddress, uint256 pricePerTokenInWei, uint256 publications, uint256 maxPublications, bool active, address additionalPayee, uint256 thirdAddressPercentage) {
        artistAddress = projects[_projectId].artistAddress;
        pricePerTokenInWei = projects[_projectId].pricePerTokenInWei;
        publications = projects[_projectId].publications;
        maxPublications = projects[_projectId].maxPublications;
        active = projects[_projectId].active;
        additionalPayee = projects[_projectId].additionalPayee;
        thirdAddressPercentage = projects[_projectId].thirdAddressPercentage;
    }

    function projectScriptInfo(uint256 _projectId) view public returns (string memory scriptJSON, uint256 scriptCount, string memory resourceIpfsHash, bool locked) {
        scriptJSON = projects[_projectId].scriptJSON;
        scriptCount = projects[_projectId].scriptCount;
        resourceIpfsHash = projects[_projectId].resourceIpfsHash;
        locked = projects[_projectId].locked;
    }

    function projectScriptByIndex(uint256 _projectId, uint256 _index) view public returns (string memory){
        return projects[_projectId].scripts[_index];
    }

    function projectURIInfo(uint256 _projectId) view public returns (string memory projectBaseURI, string memory resourceBaseIpfsURI) {
        projectBaseURI = projects[_projectId].projectBaseURI;
        resourceBaseIpfsURI = projects[_projectId].resourceBaseIpfsURI;
    }

    function projectShowAllTokens(uint _projectId) public view returns (uint256[] memory){
        return projectIdToTokenIds[_projectId];
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    function getRoyaltyData(uint256 _tokenId) public view returns (address artistAddress, address additionalPayee, uint256 thirdAddressPercentage, uint256 royaltyFeeByID) {
        artistAddress = projects[tokenIdToProjectId[_tokenId]].artistAddress;
        additionalPayee = projects[tokenIdToProjectId[_tokenId]].additionalPayee;
        thirdAddressPercentage = projects[tokenIdToProjectId[_tokenId]].thirdAddressPercentage;
        royaltyFeeByID = projects[tokenIdToProjectId[_tokenId]].secondMarketRoyalty;
    }

    function tokenURI(uint256 _tokenId) external view onlyValidTokenId(_tokenId) returns (string memory) {
        return Strings.strConcat(projects[tokenIdToProjectId[_tokenId]].projectBaseURI, Strings.uint2str(_tokenId));
    }
}