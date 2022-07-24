// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/*          _       _         
 *         (_)     | |        
 *          _  ___ | |__  ___ 
 *         | |/ _ \| '_ \/ __|
 *         | | (_) | |_) \__ \
 *         | |\___/|_.__/|___/
 *        _/ |                
 *       |__/                       
 */     
import "./JobTransferFunction.sol";
import "./Companies.sol";
import "./Seniority.sol";
import "./Titles.sol";
import "./FinanceDept.sol";
import "./Salaries.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract Jobs is ERC721, ERC721Royalty, AccessControl {
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private baseURI = "https://jobs.regular.world/cards/id/"; 
    bool public mintOpen = false;

    mapping(uint => bool) public minted;                // Regular Ids that have already claimed
    mapping(uint => uint) public timestamps;            // timestamps for claiming salary
    mapping(uint => uint) public companyIds;            // companyIds              
    mapping(uint => uint) public regIds;                // Each job NFT has an assigned RegId
    mapping(uint => uint) public jobByRegId;            // JobID by RegID

    JobTransferFunction jobTransferFunction;
    Companies companies;
    FinanceDept financeDept;
    Salaries salaries;
    Seniority seniority;
    Titles titles;
    ERC721Enumerable regularsNFT;       

    event Mint(uint jobId, uint indexed companyId, uint regularId);
    event Update(uint jobId, uint indexed companyId, uint regularId, string name);
    event RegularIdChange (uint256 indexed jobId, uint regId);
    event ResetJob (uint256 indexed jobId);

    constructor() ERC721("Regular Jobs", "JOBS") {
        _setDefaultRoyalty(msg.sender, 500);
        regularsNFT = ERC721Enumerable(0x6d0de90CDc47047982238fcF69944555D27Ecb25);
        salaries = new Salaries(address(this));
        financeDept = new FinanceDept();
        jobTransferFunction = new JobTransferFunction();
        companies = new Companies();
        seniority = new Seniority();
        titles = new Titles(address(seniority));
        financeDept.setJobsByAddr(address(this));
        financeDept.setSalariesByAddr(address(salaries));
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, address(financeDept));
        _grantRole(MINTER_ROLE, address(jobTransferFunction)); 
    }

// Primary Functions

    function safeMint(address _to, uint _regId) public {  
        require(regularsNFT.ownerOf(_regId) == _to);  
        require(!minted[_regId], "Already claimed");
        require(mintOpen, "Not minting");
        require(!hasJob(_regId),"Reg is working another job");
        minted[_regId] = true;
        (uint _jobId, uint _companyId) = companies.makeNewJob(_regId);
        timestamps[_jobId] = block.timestamp;
        companyIds[_jobId] = _companyId;
        regIds[_jobId] = _regId;
        jobByRegId[_regId] = _jobId;            
        if (companies.isManager(_regId)){ // set Managers as seniority 2
            if (seniority.level(_jobId) == 0) 
                seniority.setLevel(_jobId,2);
            else 
                seniority.incrementLevel(_jobId);
        }
        _safeMint(_to, _jobId);
        emit Mint(_jobId, _companyId, _regId);
    }

    function setRegularId(uint _jobId, uint _regId) public {
        require(ownerOf(_jobId) == msg.sender, "Not owner of this job.");
        require(regularsNFT.ownerOf(_regId) == msg.sender, "Not owner of Regular");
        require(regIds[_jobId] != _regId, "This reg already assigned to this job");
        require(hasJob(_regId) == false, "This reg already assigned to another job");
        uint _prevRegId = regIds[_jobId];
        regIds[_jobId] = _regId;   
        jobByRegId[_prevRegId] = 0;             
        jobByRegId[_regId] = _jobId;                 
        timestamps[_jobId] = block.timestamp;                             
        emit RegularIdChange(_jobId, _regId);
    }

    function unassignRegularId(uint _jobId) public {
        require(ownerOf(_jobId) == msg.sender, "Not owner of this job.");
        uint _oldRegId = regIds[_jobId];
        regIds[_jobId] = 10000;   
        jobByRegId[_oldRegId] = 0;              // SAVE REG -> JOB 
        timestamps[_jobId] = block.timestamp;                            
        emit ResetJob(_jobId);
    }

    function safeMintMany(address _to, uint[] memory _regIds) public { 
        for (uint i; i< _regIds.length;i++){
            safeMint(_to, _regIds[i]);
        }
    }

// Admin Functions

    function toggleMinting() public onlyRole(MINTER_ROLE) {
        mintOpen = !mintOpen;
    }

    function setBaseURI(string memory _newPath) public onlyRole(MINTER_ROLE) {
        baseURI = _newPath;
    }

// Other MINTER_ROLE Functions

    function resetJob(uint _jobId) public onlyRole(MINTER_ROLE) {
        uint _oldRegId = regIds[_jobId];
        regIds[_jobId] = 10000;                 // There is no #10,000
        jobByRegId[_oldRegId] = 0;              
        timestamps[_jobId] = block.timestamp;   // Reset timestamp                         
        emit ResetJob(_jobId);
    }

    function setTimestamp(uint _jobId, uint _timestamp) public onlyRole(MINTER_ROLE) {
        timestamps[_jobId] = _timestamp;
    }

    function setCompany(uint _jobId, uint _companyId) external onlyRole(MINTER_ROLE){
        companyIds[_jobId] = _companyId;
    }

    function setRegId(uint _jobId, uint _regId) external onlyRole(MINTER_ROLE){
        regIds[_jobId] = _regId;
    }

    function setJobByRegId(uint _regId, uint _jobId) public onlyRole(MINTER_ROLE) {
        jobByRegId[_regId] = _jobId;
    }

// View Functions

    function sameOwner(uint _jobId) public view returns (bool) {
        return ownerOf(_jobId) == ownerOfReg(regIds[_jobId]);
    }

    function getTimestamp(uint _jobId) public view returns (uint) {
        require(_exists(_jobId), "Query for nonexistent token");
        return timestamps[_jobId];
    }

    function getCompanyId(uint _jobId) public view returns (uint) {
        require(_exists(_jobId), "Query for nonexistent token");
        return companyIds[_jobId];
    }

    function getRegId(uint _jobId) public view returns (uint) {
        require(_exists(_jobId), "Query for nonexistent token");
        return regIds[_jobId];
    }

    function isUnassigned(uint _jobId) public view returns (bool) {
        require(_exists(_jobId), "Query for nonexistent token");
        return regIds[_jobId] == 10000; 
    }

    function getJobByRegId(uint _regId) public view returns (uint) {
        return jobByRegId[_regId];
    }

    function hasJob(uint _regId) public view returns (bool) {
        return jobByRegId[_regId] != 0;
    }

    function getJobFullDetails(uint _jobId) public view returns (uint, uint, uint, string memory, uint, string memory){
        require(_exists(_jobId), "Query for nonexistent token");
        uint _salary = salaries.salary(_jobId);
        uint _regId = regIds[_jobId];
        uint _companyId = companyIds[_jobId];
        string memory _companyName = companies.getName(_companyId);
        uint _seniority = seniority.level(_jobId);
        string memory _title = titles.title(_jobId);
        return (_salary, _regId, _companyId, _companyName, _seniority, _title);
    }

// function with external calls

   function getBaseSalary(uint _companyId) public view returns (uint) { 
        return companies.getBaseSalary(_companyId);
    }
    
    function getCompanyName(uint _companyId) public view returns (string memory) {
        return companies.getName(_companyId);
    }
    
    function getSpread(uint _companyId) public view returns (uint) {
        return companies.getSpread(_companyId);
    }
    
    function getCapacity(uint _companyId) public view returns (uint) {
        return companies.getCapacity(_companyId);
    }

    function getSalary(uint _jobId) public view returns (uint) {
        require(_exists(_jobId), "Query for nonexistent token");
        return salaries.salary(_jobId);
    }

    function getSeniorityLevel(uint _jobId) public view returns (uint) {
        // require(_exists(_jobId), "Query for nonexistent token");
        return seniority.level(_jobId);
    }

    function title(uint _jobId) public view returns (string memory) {
        require(_exists(_jobId), "Query for nonexistent token");
        return titles.title(_jobId);
    }

    function ownerOfReg(uint _regId) public view returns (address) {
        return regularsNFT.ownerOf(_regId);
    }

// Setting and getting contract addresses

    // setting

    function setContractAddr(string memory _contractName, address _addr) public onlyRole(MINTER_ROLE){
        bytes memory _contract = bytes(_contractName);
        if (keccak256(_contract) == keccak256(bytes("JobTransferFunction"))) {
            jobTransferFunction = JobTransferFunction(_addr);
        } else if (keccak256(_contract) == keccak256(bytes("Companies"))) {
            companies = Companies(_addr);
        } else if (keccak256(_contract) == keccak256(bytes("FinanceDept"))) {
            financeDept = FinanceDept(_addr);
        } else if (keccak256(_contract) == keccak256(bytes("Seniority"))) {
            seniority = Seniority(_addr);
        } else if (keccak256(_contract) == keccak256(bytes("Titles"))) {
            titles = Titles(_addr);
        } else if (keccak256(_contract) == keccak256(bytes("Salaries"))) {
            salaries = Salaries(_addr);
        } else
            revert("No match found");
    }

    // getting

    function getContractAddr(string memory _contractName) public view returns (address) {
        bytes memory _contract = bytes(_contractName);
        if (keccak256(_contract) == keccak256(bytes("JobTransferFunction"))) {
            return address(jobTransferFunction);
        } else if (keccak256(_contract) == keccak256(bytes("Companies"))) {
            return address(companies);
        } else if (keccak256(_contract) == keccak256(bytes("FinanceDept"))) {
            return address(financeDept);
        } else if (keccak256(_contract) == keccak256(bytes("Seniority"))) {
            return address(seniority);
        } else if (keccak256(_contract) == keccak256(bytes("Titles"))) {
            return address(titles);
        } else if (keccak256(_contract) == keccak256(bytes("Salaries"))) {
            return address(salaries);
        } else
            revert("None found");
    }

    function setDefaultRoyalty(address _receiver, uint _basisPoints) public onlyRole(MINTER_ROLE){
        setDefaultRoyalty(_receiver, _basisPoints);
    }

// Overrides

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        if (from != address(0)){ // if not minting, then reset on transfer
            jobTransferFunction.jobTransfer(from,to,tokenId); 
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

// Proxy Methods

    function allRegularsByAddress(address _wallet) public view returns(uint[] memory){
        uint[] memory nfts = new uint[](regularsNFT.balanceOf(_wallet));
        for (uint i = 0; i < nfts.length;i++){
            nfts[i] = regularsNFT.tokenOfOwnerByIndex(_wallet, i);
        }
        return nfts;
    }

    // Should we set a limit here?
    function unmintedByAddress(address _wallet) public view returns(uint[] memory){
        uint unmintedCount = 0;
        // scan through all regs and count the unminted ones
        for (uint i = 0; i < regularsNFT.balanceOf(_wallet);i++){
            uint _regId = regularsNFT.tokenOfOwnerByIndex(_wallet, i);
            if (!minted[_regId])
                unmintedCount++;
        }
        // add unminted to the array
        uint[] memory nfts = new uint[](unmintedCount);
        for (uint i = 0; i < nfts.length;i++){
            uint _regId = regularsNFT.tokenOfOwnerByIndex(_wallet, i);
            if (!minted[_regId])
                nfts[i] = _regId;
        }
        return nfts;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Transfer Function v1.0 
 */

import "@openzeppelin/contracts/access/AccessControl.sol";

// This function is called when a Job NFT is transferred

interface JobsInterface {
    function resetJob(uint _jobId) external;
}

contract JobTransferFunction is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address jobsAddress;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _grantRole(MINTER_ROLE, tx.origin);
        _grantRole(MINTER_ROLE, msg.sender);
        jobsAddress = msg.sender;
    }

    function jobTransfer(address from, address to, uint256 tokenId) public onlyRole(MINTER_ROLE) { 
        JobsInterface(jobsAddress).resetJob(tokenId);
    }

}

pragma solidity ^0.8.12;
// SPDX-License-Identifier: MIT

/**
 * @title Regular Companies v1.0 
 */

import "./Random.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// "special" companies are for a set of Regular IDs that share a trait, like McD's workers
// "not-special" companies get assigned to regular IDs randomly.

contract Companies is AccessControl {
    using Random for Random.Manifest;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint public constant SALARY_DECIMALS = 2;
    uint public SALARY_MULTIPLIER = 100;                   // basis points

    struct Company {     
        uint128 baseSalary;   
        uint128 capacity;        
    }

    Company[60] companies;                                  // Companies by ID
    uint16[60] indexes;                                     // the starting index of the company in array of job IDs
    uint16[60] counts;
    Random.Manifest private mainDeck;                       // Card deck for non-special companies
    mapping(uint => Random.Manifest) private specialDecks;  // Card decks for special companies
    mapping(uint => uint) private specialCompanyIds;        // Company ID by special reg ID
    uint specialCompanyIdFlag;                              // Company ID for the first special company in the array
    uint[] _tempArray;                                      // used for parsing special IDs
    mapping(uint => bool) managerIds;                       // IDs of all McD's manager regs
    mapping(uint => string) names;                          // Company Names

    event jobIDCreated (uint256 regularId, uint newJobId, uint companyId, address sender);
    
	constructor() {
	    _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
	    _grantRole(MINTER_ROLE, tx.origin);
	    _grantRole(MINTER_ROLE, msg.sender);

// Save Names

        names[0] = "RNN News";
        names[1] = "AAAARP";
        names[2] = "Petstore";
        names[3] = "Foodtime";
        names[4] = "Hats";
        names[5] = "Bed Bath & Bodyworks";
        names[6] = "Bugs Inc.";
        names[7] = "Autoz";
        names[8] = "Office Dept.";
        names[9] = "Express";
        names[10] = "Totally Wine";
        names[11] = "Y'all";
        names[12] = "5 O'clockville";
        names[13] = "Nrfthrup Grrmng";
        names[14] = "Mall Corp.";
        names[15] = "Ice Creams";
        names[16] = "Thanky Candles";
        names[17] = "Hotella";
        names[18] = "Berkshire Thataway";
        names[19] = "Kopies";
        names[20] = "Sprayers";
        names[21] = "'Onuts";
        names[22] = "Tax Inc.";
        names[23] = "Khols";
        names[24] = "Black Pebble";
        names[25] = "Haircuts Inc.";
        names[26] = "Global Gas";
        names[27] = "Block";
        names[28] = "Eyeglasses";
        names[29] = "Books & Mags";
        names[30] = "Meme";
        names[31] = "Coin";
        names[32] = "Wonder";
        names[33] = "iSecurity";
        names[34] = "Dairy Lady";
        names[35] = "Big Deal MGMT";
        names[36] = "Spotlight Talent";
        names[37] = "Rock Solid Insurance";
        names[38] = "Safe Shield Insurance";
        names[39] = "Bit";
        names[40] = "Whoppy Jrs.";
        names[41] = "WGMI Inc.";
        names[42] = "Global International";
        names[43] = "N.E.X.T. Rugs";
        names[44] = "Alpha Limited";
        names[45] = "Best Shack";
        names[46] = "Partners & Partners";
        names[47] = "Boss E-systems";
        names[48] = "Blockbusters";
        names[49] = "Hexagon Research Group";
        names[50] = "Crabby Shack";
        names[51] = "Dollar Store";
        names[52] = "UP Only";
        names[53] = "Frito Pay";
        names[54] = "Hot Pockets";
        names[55] = "Spooky";
        names[56] = "GM";
        names[57] = "McDanny's";
        names[58] = "Wendy's";
        names[59] = "Party Place";     
      
// Init companies
        
        companies[0] =  Company({ capacity : 212, baseSalary : 1950 });
        companies[1] =  Company({ capacity : 350, baseSalary : 1300 });
        companies[2] =  Company({ capacity : 120, baseSalary : 3725 });
        companies[3] =  Company({ capacity : 144, baseSalary : 3175 });
        companies[4] =  Company({ capacity : 168, baseSalary : 2375 });
        companies[5] =  Company({ capacity : 160, baseSalary : 2475 });
        companies[6] =  Company({ capacity : 100, baseSalary : 4400 });
        companies[7] =  Company({ capacity : 184, baseSalary : 2200 });
        companies[8] =  Company({ capacity : 500, baseSalary : 1025 });
        companies[9] =  Company({ capacity : 188, baseSalary : 2150 });
        companies[10] = Company({ capacity : 140, baseSalary : 3250 });
        companies[11] = Company({ capacity :  96, baseSalary : 4575 });
        companies[12] = Company({ capacity :  50, baseSalary : 7550 });
        companies[13] = Company({ capacity : 192, baseSalary : 2100 });
        companies[14] = Company({ capacity :  92, baseSalary : 4750 });
        companies[15] = Company({ capacity : 156, baseSalary : 2525 });
        companies[16] = Company({ capacity : 176, baseSalary : 2275 });
        companies[17] = Company({ capacity : 148, baseSalary : 3100 });
        companies[18] = Company({ capacity : 200, baseSalary : 2050 });
        companies[19] = Company({ capacity : 136, baseSalary : 3350 });
        companies[20] = Company({ capacity : 204, baseSalary : 2000 });
        companies[21] = Company({ capacity : 104, baseSalary : 4250 });
        companies[22] = Company({ capacity : 218, baseSalary : 1900 });
        companies[23] = Company({ capacity :  57, baseSalary : 6675 });
        companies[24] = Company({ capacity : 196, baseSalary : 2075 });
        companies[25] = Company({ capacity : 206, baseSalary : 2000 });
        companies[26] = Company({ capacity : 210, baseSalary : 1950 });
        companies[27] = Company({ capacity :  88, baseSalary : 4950 });
        companies[28] = Company({ capacity : 214, baseSalary : 1925 });
        companies[29] = Company({ capacity : 242, baseSalary : 1750 });
        companies[30] = Company({ capacity : 124, baseSalary : 3625 });
        companies[31] = Company({ capacity : 164, baseSalary : 2425 });
        companies[32] = Company({ capacity : 116, baseSalary : 3850 });
        companies[33] = Company({ capacity : 180, baseSalary : 2225 });
        companies[34] = Company({ capacity : 172, baseSalary : 2325 });
        companies[35] = Company({ capacity : 132, baseSalary : 3425 });
        companies[36] = Company({ capacity : 152, baseSalary : 3025 });
        companies[37] = Company({ capacity : 450, baseSalary : 1100 });
        companies[38] = Company({ capacity : 600, baseSalary : 900 });
        companies[39] = Company({ capacity : 112, baseSalary : 3975 });
        companies[40] = Company({ capacity :  65, baseSalary : 5900 });
        companies[41] = Company({ capacity :  76, baseSalary : 5500 });
        companies[42] = Company({ capacity :  80, baseSalary : 5400 });
        companies[43] = Company({ capacity :  84, baseSalary : 5150 });
        companies[44] = Company({ capacity : 290, baseSalary : 1500 });
        companies[45] = Company({ capacity : 108, baseSalary : 4100 });
        companies[46] = Company({ capacity : 276, baseSalary : 1575 });
        companies[47] = Company({ capacity : 400, baseSalary : 1200 });
        companies[48] = Company({ capacity :  53, baseSalary : 7150 });
        companies[49] = Company({ capacity : 300, baseSalary : 1475 });
        companies[50] = Company({ capacity :  69, baseSalary : 5875 });
        companies[51] = Company({ capacity :  72, baseSalary : 5650 });
        companies[52] = Company({ capacity : 208, baseSalary : 1975 });
        companies[53] = Company({ capacity : 128, baseSalary : 3525 });
        companies[54] = Company({ capacity :  73, baseSalary : 5575 });

// Specials companies

        // 55 Spooky
        _tempArray = [
            379, 391, 874, 1004, 1245, 1258, 1398, 1584, 1869, 1940, 1952, 2269, 2525, 2772, 3055, 3455, 3472, 3541, // 30 Clowns
            3544, 3607, 3617, 4103, 4117, 4149, 4195, 4230, 4425, 5065, 5101, 5188,
            4, 27, 48, 101, 136, 143, 157, 165, 172, 175, 226, 277, 388, 389, 418, 420, 444, 457, 493, 516, 518,  // 31 Heavy Makeup 
            610, 638, 679, 681, 703, 743, 784, 867, 917, 959
        ];
        parseSpecialRegIDs(55,_tempArray, 6250); 

        // 56 GM
        _tempArray = [
            4466, 4684, 5342, 5437, 5932, 6838, 8043, 1175, 1274, 2005, 2497, 2592, 3063, 3285, 3300, 3316,   // 32 Devils
            3454, 3983, 4541, 4856, 5171, 5219, 5265, 6643, 6719, 6982, 7147, 7303, 8012, 8944, 9644, 9822,
            1013, 1032, 1042, 1084, 1127, 1142, 1196, 1234, 1279, 1295, 1296, 1297, 1310, 1323, 1356, 1390, 1405  // 17 Heavy makeup
        ];
        parseSpecialRegIDs(56,_tempArray, 7700);

        // 57 McDanny's
        _tempArray = [
            1617, 1808, 2149, 2632, 2833, 2847, 3301, 3524, 4822, 5139, 5735, 5906, 5946, 6451, 6663, 6762, 6831,  // McD's Workers + Managers
            7278, 7519, 8365, 9434, 64, 488, 642, 946, 1014, 1650, 1823, 1949, 2178, 2593, 2992, 3070, 3331, 3745, 
            3944, 3961, 4030, 4070, 4090, 4197, 4244, 4719, 5551, 5761, 5779, 5895, 6044, 6048, 6276, 6599, 6681, 
            6832, 6873, 6889, 7124, 7550, 7975, 8130, 8579, 8599, 8689, 8784, 8794, 8903, 9053, 9205, 9254, 9407, 9994
        ];
        parseSpecialRegIDs(57,_tempArray, 8250); 

        // 58 Wendy's
        _tempArray = [
            317, 456, 878, 1588, 2702, 2974, 3047, 3224, 3308, 3441, 4082, 4107, 5490, 5574, 5622, 6232, 6317,  // Wendys Workers
            6350, 6404, 6539, 7654, 7947, 7961, 8248, 8400, 8437, 8643, 8667, 8728, 9221, 9611, 9709, 9754, 9950
        ];
        parseSpecialRegIDs(58,_tempArray, 7900);

        // 59 Party Place - 25 Clowns + 26 heavy makeup
        _tempArray = [
            5494, 5845, 6016, 6042, 6073, 6109, 6436, 6649, 7092, 7574, 7863, 8077, 8110, 8326, 8359, 8480, 8629,  // 25 Clowns
            8825, 9303, 9319, 9339, 9770, 9800, 9858, 9870,
            1440, 1482, 1566, 1596, 1598, 1660, 1663, 1695, 1700,   // 26 heavy makeup
            1708, 1905, 1929, 1986, 2018, 2026, 2037, 2067, 2097, 2125, 2148, 2176, 2207, 2247, 2262, 2347, 2494
        ];
        parseSpecialRegIDs(59,_tempArray, 7425);

// McD's managers

        // These Ids are only used for seniority level bonus, on mint
        _tempArray = [1617, 1808, 2149, 2632, 2833, 2847, 3301, 3524, 4822, 5139, 5735, 5906, 5946, 6451, 6663,  // 21 Managers
        6762, 6831, 7278, 7519, 8365, 9434 ]; 

        for (uint i = 0;i < _tempArray.length;i++){
            managerIds[_tempArray[i]] = true;
        }

//  
        specialCompanyIdFlag = 55;
        
        uint jobCountNotSpecial = 0;
        for (uint i = 0; i < specialCompanyIdFlag; i++) {
            jobCountNotSpecial += companies[i].capacity;
        }
        mainDeck.setup(jobCountNotSpecial);

        uint jobCountSpecial = 0;
        for (uint i = specialCompanyIdFlag; i < numCompanies(); i++) {
            jobCountSpecial += companies[i].capacity;
        }

        uint _startIndex = 0;
        for (uint i = 0; i < numCompanies(); i++) {
            indexes[i] = uint16(_startIndex);
            _startIndex += companies[i].capacity;
        }
	}

// Admin Functions

    function makeNewJob(uint _regularId) public onlyRole(MINTER_ROLE) returns (uint, uint) {
        uint _pull;
        uint _specialCompanyId = specialCompanyIds[_regularId];
        uint _newJobId;
        if (_specialCompanyId == 0) {   
            // If Regular id is NOT special
            _pull = mainDeck.draw();
            uint _companyId = getCompanyId(_pull);
            counts[_companyId]++;
            emit jobIDCreated(_regularId, add1(_pull), _companyId, msg.sender);
            return (add1(_pull), _companyId);             
        } else {                        
            // If Regular id IS special
            _pull = specialDecks[_specialCompanyId].draw();
            _newJobId = _pull + indexes[_specialCompanyId];
            counts[_specialCompanyId]++;
            emit jobIDCreated(_regularId, add1(_newJobId), _specialCompanyId, msg.sender);
            return (add1(_newJobId), _specialCompanyId); 
        } 
    }

    function updateCompany(uint _companyId, uint128 _baseSalary, string memory _name) public onlyRole(MINTER_ROLE)  {
        companies[_companyId].baseSalary = _baseSalary;
        names[_companyId] = _name;
    } 

    function setSalaryMultiplier(uint _basispoints) public onlyRole(MINTER_ROLE) {
        SALARY_MULTIPLIER = _basispoints;
    }

// View Functions

    function getCount(uint _companyId) public view returns (uint) {
        return counts[_companyId];
    }

    function getBaseSalary(uint _companyId) public view returns (uint) {
        return companies[_companyId].baseSalary * SALARY_MULTIPLIER / 100;
    }

    function getSpread(uint _companyId) public pure returns (uint) {
        uint _nothing = 12345;
        return uint(keccak256(abi.encodePacked(_companyId + _nothing))) % 40;
    }

    function getCapacity(uint _companyId) public view returns (uint) {
        return companies[_companyId].capacity;
    }

    function numCompanies() public view returns (uint) {
        return companies.length;
    }

    function isManager(uint _regId) public view returns (bool) {
        return managerIds[_regId];
    }

    function maxJobIds() public view returns (uint) {
        uint _total = 0;
        for (uint i = 0; i < numCompanies(); i++) {
            _total += companies[i].capacity;
        }
        return _total;
    }

    function getName(uint _companyId) public view returns (string memory) {
        return names[_companyId];
    }

// Internal

    function getCompanyId(uint _jobId) internal view returns (uint) {
        uint _numCompanies = companies.length;
        uint i;
        for (i = 0; i < _numCompanies -1; i++) {
            if (_jobId >= indexes[i] && _jobId < indexes[i+1])
                break;
        }
        return i;
    }

    function parseSpecialRegIDs(uint _companyId, uint[] memory _ids, uint _baseSalary) internal {
        for (uint i = 0;i < _ids.length; i++) {
            specialCompanyIds[_ids[i]] = _companyId;
        }
        companies[_companyId] = Company({ capacity : uint128(_ids.length), baseSalary : uint128(_baseSalary) }); 
        specialDecks[_companyId].setup(_ids.length);
    }

    function add1(uint _x) internal pure returns (uint) {
        return _x + 1;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title Regular Seniority v1.0 
 */

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Seniority is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint public MAX_LEVELS = 5;
    mapping(uint => uint) private levels;

    event LevelUpdate (uint _tokenId, uint _newLevel);

    constructor() {
	    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	    _grantRole(MINTER_ROLE, msg.sender);
	    _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
	    _grantRole(MINTER_ROLE, tx.origin);
	}

    function level(uint _jobID) public view returns (uint) {
        // jobs start with level 0 or 1, based on a cointoss;
        return levels[_jobID] + cointoss(_jobID);
    }

    // Admin

    function incrementLevel(uint _jobID) public onlyRole(MINTER_ROLE) {
        require(level(_jobID) < MAX_LEVELS, "At max level");
        levels[_jobID] += 1;
        emit LevelUpdate(_jobID, level(_jobID));
    }

    function setLevel(uint _jobID, uint _newLevel) public onlyRole(MINTER_ROLE) {
        require(_newLevel <= MAX_LEVELS, "Level too high");
        levels[_jobID] = _newLevel;
        emit LevelUpdate(_jobID, level(_jobID));
    }

    function setMaxLevels(uint _newMax) public onlyRole(MINTER_ROLE) {
        MAX_LEVELS = _newMax;
    }

    // Internal

    function cointoss(uint _num) internal pure returns (uint){
        return (uint(keccak256(abi.encodePacked(_num))) % 2);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title Regular Titles v1.0 
 */

import "./Seniority.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// TO-DO: Titles still exceed the max chars

contract Titles is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint public constant MAX_LEVELS = 5;
    uint public MAX_CHARS = 28;
    mapping(uint => string) private customs;
    mapping(uint => bool) public customExists;
    Seniority seniority;

    event SeniorityUpdate (uint _tokenId, uint _newLevel, string _newPrefix);
    event TitleUpdate (uint _tokenId, string _newTitle);

// define values

    string[] private entryLevelTitles = [
        "Asst.", 
        "Asst. to", 
        "Jr."
    ];

    string[] private PRE = [
        "Entry Level",
        "",
        "Lead",
        "Sr.",
        "VP",
        "Chief"
    ];

    string[] private A = [
        // "Night-shift",
        "Office",
        "Account",
        "Program",
        "Project",
        "Regional",
        "Branch"
    ];

    string[] private B = [
        "Department",
        "Team",
        "Facilities",
        "Compliance",
        "Mailroom",
        "Finance",
        "Sales",
        "Marketing",
        "IT",
        "HR",
        "Operations",
        "Community",
        "Business",
        "Technical",
        "Helpdesk",
        "Custodial",
        "Data-Entry"
    ];

    string[] private C = [
        "Officer",
        "Accountant",
        "Associate",
        "Leader",
        "Clerk",
        "Administrator",
        "Consultant",
        "Coordinator",
        "Inspector",
        "Rep.",
        "Support",
        "Auditor",
        "Specialist",
        "Analyst",
        "Executive",
        "Controller",
        "Programmer",
        "Developer",
        "Support",
        "Professional",
        "Salesperson",
        "Receptionist"
    ];

//

    constructor(address _addr) {
	    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	    _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
	    _grantRole(MINTER_ROLE, msg.sender);
	    _grantRole(MINTER_ROLE, tx.origin);
        seniority = Seniority(_addr);
	}

// Public View

    function title(uint _jobID) public view returns (string memory) {
        if (customExists[_jobID])
            return (customs[_jobID]);
        string memory _prefix = titlePrefix(_jobID);
        string memory _a;
        string memory _b;
        string memory _c;
        (_a,_b,_c) = titleSeperated(_jobID);

        bool _isAssistant = keccak256(abi.encodePacked((_prefix))) == keccak256(abi.encodePacked((entryLevelTitles[0]))); 
        bool _makeSuffix = (_isAssistant && cointoss(_jobID + 10000)); // move "assistant" to end, half the time
        
        // shorten job if it's bigger than max characters
        uint _jobLength = bytes(_prefix).length + bytes(_a).length + bytes(_b).length + bytes(_c).length + 3; // add 3 characters for spaces
        if (_jobLength > MAX_CHARS) { 
            // reduce number of words
            if (cointoss(_jobID)){
                if (_makeSuffix)
                    return myConcat(_b,_c,_prefix,"");
                else
                    return myConcat(_prefix,_b,_c,"");
            } else {
                if (_makeSuffix)
                    return myConcat(_a, _c, _prefix, "");
                else
                    return myConcat(_prefix,_a, _c, "");
            }
        } else {
            if (_makeSuffix)
                return myConcat(_a, _b, _c, titlePrefix(_jobID));
            else 
                return myConcat(titlePrefix(_jobID),_a, _b, _c);
        }
    }   

    function level(uint _jobID) public view returns (uint) {
        return seniority.level(_jobID);
    }

// Admin

    function setCustomTitle(uint _jobID, string memory _newTitle) public onlyRole(MINTER_ROLE) {
        customs[_jobID] = _newTitle;
        customExists[_jobID] = true;
        emit TitleUpdate(_jobID,_newTitle);
    }

    function setMaxChars(uint _newMax) public onlyRole(MINTER_ROLE) {
        MAX_CHARS = _newMax;
    }

// Contract Management
    
    function seniorityContractAddress() public view returns (address) {
        return address(seniority);
    }

    function setSeniorityContractAddr(address _addr) public onlyRole(MINTER_ROLE) {
        seniority = Seniority(_addr);
    }

// internal

    function titleSeperated(uint _jobID) internal view returns (string memory,string memory,string memory) {
        uint _a = uint(keccak256(abi.encodePacked(_jobID))) % A.length;
        uint _b = uint(keccak256(abi.encodePacked(_jobID,"abc"))) % B.length;
        uint _c = uint(keccak256(abi.encodePacked(_jobID,"def"))) % C.length;
        return (A[_a],B[_b],C[_c]);
    }

    function myConcat(string memory s1, string memory s2, string memory s3, string memory s4) internal pure returns (string memory) {
        string memory result;
        if (bytes(s1).length > 0) 
            result = string.concat(s1, " ", s2," ", s3);
        else    
            result = string.concat(s2," ", s3);
        if (bytes(s4).length > 0)
            result = string.concat(result, " ", s4);
        return result;
    }

    function titlePrefix(uint _jobID) internal view returns (string memory) {
        if (level(_jobID) == 0) {
            uint _x = uint(keccak256(abi.encodePacked(_jobID))) % entryLevelTitles.length;
            return entryLevelTitles[_x];
        } else if (level(_jobID) == 1) {
            return "";
        } else {
            return PRE[level(_jobID)];    
        }
    }

    function cointoss(uint _num) internal pure returns (bool){
        return (uint(keccak256(abi.encodePacked(_num))) % 2 == 0);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title SalaryDept v1.0
 *  
 *  This contract determines salaries + pay schedule
 *  
 * @dev
 * - Upon deployment
 *   - constructor requires address of Jobs contract
 *   - Set minter role to Jobs contract for FinanceDept address
 *   - Set minter role to RegularToken ERC20 contract for FinaceDept address
 */

import "./RegularToken.sol";
import "./Jobs.sol";
import "./Salaries.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract FinanceDept is AccessControl, Pausable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint public payDuration = 1 weeks;
    uint public maxClaimTime = 10 weeks;
	RegularToken regularsToken;
    Jobs jobs;
    Salaries salaries;

    event ClaimedSalary (address wallet, uint amount);
    event ClaimedSalaries (address wallet, uint amount);

    constructor() { 
        _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
	    _grantRole(MINTER_ROLE, msg.sender);
	    _grantRole(MINTER_ROLE, tx.origin);
        regularsToken = RegularToken(0x78b5C6149C87c82EDCffC73C230395abbc56DdD5); // Regulars Token on Rinkeby
    }

// GET SALARIES

    function unclaimedDuration(uint _jobId) public view returns (uint) {
        uint _duration = block.timestamp - jobs.getTimestamp(_jobId);
        return Math.min(_duration, maxClaimTime);
    }

    function unclaimedByJob(uint _jobId) public view returns (uint) {
        return salaries.salary(_jobId) * unclaimedDuration(_jobId) / payDuration;
    } 

    function unclaimedByCompany(uint[] memory _jobIds) public view returns (uint) {
        uint _companyId = jobs.getCompanyId(_jobIds[0]); 
        uint _combinedSalaries = 0; 
        uint i;
        for (i = 0; i < _jobIds.length;i++){
            uint _jobId = _jobIds[i];
            require(jobs.getCompanyId(_jobId) == _companyId, "Not all same company id");
            _combinedSalaries += unclaimedByJob(_jobId);
        }
        return salaries.teamworkBonus(_combinedSalaries, _jobIds.length, jobs.getCapacity(_companyId));
    }

    function unclaimedAll(uint[] memory _jobIds) public view returns (uint) {
        return 100;
    }

// CLAIM

    // function claimByJob(uint _jobId) public whenNotPaused {
    //     require(jobs.ownerOf(_jobId) == msg.sender, "Not the owner of this job");
    //     require(!jobs.isUnassigned(_jobId),"No reg working the job");
    //     require(jobs.ownerOfReg(jobs.getRegId(_jobId)) == msg.sender,"You don't own assigned reg");
    //     uint _amount = unclaimedByJob(_jobId);
    //     jobs.setTimestamp(_jobId, block.timestamp);
    //     regularsToken.mint(msg.sender,_amount); // SEND THE TOKENS!
    //     emit ClaimedSalary(msg.sender, _amount);
    // }

    // function claimByCompany(uint[] memory _jobIds) public whenNotPaused { // must be in same company
    //     uint _companyId = jobs.getCompanyId(_jobIds[0]);
    //     uint _combinedSalaries = 0;
    //     for (uint i = 0; i < _jobIds.length;i++){
    //         uint _jobId = _jobIds[i];
    //         require(jobs.getCompanyId(_jobId) == _companyId, "Not all same company id");
    //         require(jobs.ownerOf(_jobId) == msg.sender, "Not the owner of this job");
    //         require(!jobs.isUnassigned(_jobId),"No reg working the job");
    //         require(jobs.ownerOfReg(jobs.getRegId(_jobId)) == msg.sender,"You don't own assigned reg");
    //         _combinedSalaries += unclaimedByJob(_jobId);
    //         jobs.setTimestamp(_jobId, block.timestamp);
    //     }
    //     // for every 1% of the company that you own, you get 10% bonus
    //     uint _grandTotal = salaries.teamworkBonus(_combinedSalaries, _jobIds.length, jobs.getCapacity(_companyId));
    //     regularsToken.mint(msg.sender,_grandTotal); // SEND THE TOKENS!
    //     emit ClaimedSalaries(msg.sender, _grandTotal);
    // }

    // function claimAll(uint[][] memory _jobIdsByCompany) public whenNotPaused {
    //     // to-do
    // }

// ADMIN

    function setMaxClaimTime(uint _maxClaimTime) public onlyRole(MINTER_ROLE) {
        maxClaimTime = _maxClaimTime;
    }

    function setPayDuration(uint _payDuration) public onlyRole(MINTER_ROLE) {
        payDuration = _payDuration;
    }

    function pause() public onlyRole(MINTER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(MINTER_ROLE) {
        _unpause();
    }

// CONTRACT MANAGEMENT

    // set

    function setJobsByAddr(address _addr) public onlyRole(MINTER_ROLE){
        jobs = Jobs(_addr);
    }

    function setSalariesByAddr(address _addr) public onlyRole(MINTER_ROLE){
        salaries = Salaries(_addr);
    }

    function setRegularsToken(address _addr) public onlyRole(MINTER_ROLE) {
        regularsToken = RegularToken(_addr);
    }

    // get

    function getRegularsTokenAddress() public view returns (address) {
        return address(regularsToken);
    }

    function getJobsTokenAddress() public view returns (address) {
        return address(jobs);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title Regular Salaries 
 */

import "./Jobs.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract Salaries is AccessControl {
    uint public constant RANDOM_SEED = 69;
    uint public constant SALARY_DECIMALS = 2;
    uint public constant MAX_TEAMWORK_BONUS = 300;
    uint public SALARY_MULTIPLIER = 100;  // basis points
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Jobs jobs;

	constructor(address _addr) {
        _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
	    _grantRole(MINTER_ROLE, msg.sender);
	    _grantRole(MINTER_ROLE, tx.origin);
        jobs = Jobs(_addr);
	}

    function basepay(uint _jobId, uint _companyBase, uint _companySpread) public view returns (uint) {
        uint _baseSalary = _companyBase * 10 ** 18 * SALARY_MULTIPLIER / 100;
        uint _spread = _baseSalary * _companySpread / 100;                       // Spread value before randomization
        uint _r = uint(keccak256(abi.encodePacked(_jobId, RANDOM_SEED))) % 100;  // Random integer 0-100
        uint _result = _baseSalary + (_r * _spread / 100) - (_spread / 2);
        // return (_result / 10 ** SALARY_DECIMALS);            // NOT ROUNDED
        return (_result * 4 / 10 ** 20) * 100 / 4 * 10 ** 16;   // ROUNDED
    }

    function basepay(uint _jobId) public view returns (uint) {
        uint _companyId = jobs.getCompanyId(_jobId);
        return basepay(_jobId, companyBase(_companyId), companySpread(_companyId)); 
    }

    function seniorityBonus(uint _level, uint _basePay) public pure returns (uint) {
        uint _bonusPercent = 0;
        if (_level > 0)
            _bonusPercent = (2 ** (_level - 1) * 10); 
        return _bonusPercent * _basePay / 100; 
    }

    function seniorityBonus(uint _jobId) public view returns (uint) {
        uint _seniorityLevel = jobs.getSeniorityLevel(_jobId);
        uint _basepay = basepay(_jobId);
        return seniorityBonus(_seniorityLevel, _basepay);
    }

    function salary(uint _jobId) public view returns (uint) {
        uint _basepay = basepay(_jobId);
        uint _seniorityLevel = jobs.getSeniorityLevel(_jobId);
        uint _seniorityBonus = seniorityBonus(_seniorityLevel, _basepay);
        uint _result = _basepay + _seniorityBonus;
        return _result;
    }    

    function teamworkBonus(uint _numOwned, uint _capacity) public pure returns (uint) { 
        // 10% bonus for every 1% of the company that you own .. total jobs owned must be > 1
        // returns a percent
        uint _result = 0;
        if (_numOwned > 1)
          _result = (_numOwned * 100 / _capacity) * 10;
        return Math.min(_result,MAX_TEAMWORK_BONUS);
    }

    function teamworkBonus(uint _totalSalaries, uint _numOwned, uint _capacity) public pure returns (uint) { 
        return _totalSalaries + (_totalSalaries * teamworkBonus(_numOwned, _capacity) / 100);
    }

    function teamworkBonus(uint[] memory _jobIds) public view returns (uint) { 
        uint _companyId = jobs.getCompanyId(_jobIds[0]); // company IDs must match
        uint _totalSalaries = 0; 
        for (uint i = 0; i < _jobIds.length;i++){
            uint _jobId = _jobIds[i];
            require(jobs.getCompanyId(_jobId) == _companyId, "Not all same company id");
            _totalSalaries += salary(_jobId);
        }
        return teamworkBonus(_totalSalaries , _jobIds.length, jobs.getCapacity(_companyId));
    }

    // from Jobs contract

    function companyBase(uint _companyId) public view returns (uint) {
        return jobs.getBaseSalary(_companyId);
    }

    function companySpread(uint _companyId) public view returns (uint) {
        return jobs.getSpread(_companyId);
    }

    // Admin

    function setJobsAddr(address _addr) public onlyRole(MINTER_ROLE) {
        jobs = Jobs(_addr);
    }

    function setSalaryMultiplier(uint _basispoints) public onlyRole(MINTER_ROLE) {
        SALARY_MULTIPLIER = _basispoints;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/ERC721Royalty.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../common/ERC2981.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev Extension of ERC721 with the ERC2981 NFT Royalty Standard, a standardized way to retrieve royalty payment
 * information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC721Royalty is ERC2981, ERC721 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

pragma solidity ^0.8.0;

library Random {
    function random() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender)) ;
    }

    struct Manifest {
        uint256[] _data;
    }

    function setup(Manifest storage self, uint256 length) internal {
        uint256[] storage data = self._data;

        require(data.length == 0, "cannot-setup-during-active-draw");
        assembly { sstore(data.slot, length) }
    }

    function draw(Manifest storage self) internal returns (uint256) {
        return draw(self, random());
    }

    function draw(Manifest storage self, bytes32 seed) internal returns (uint256) {
        uint256[] storage data = self._data;

        uint256 l = data.length;
        uint256 i = uint256(seed) % l;
        uint256 x = data[i];
        uint256 y = data[--l];
        if (x == 0) { x = i + 1;   }
        if (y == 0) { y = l + 1;   }
        if (i != l) { data[i] = y; }
        data.pop();
        return x - 1;
    }

    function put(Manifest storage self, uint256 i) internal {
        self._data.push(i + 1);
    }

    function remaining(Manifest storage self) internal view returns (uint256) {
        return self._data.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** 
 *      ____  ____  ___  _  _  __     __   ____     
 *     (  _ \(  __)/ __)/ )( \(  )   / _\ (  _ \    
 *      )   / ) _)( (_ \) \/ (/ (_/\/    \ )   /    
 *     (__\_)(____)\___/\____/\____/\_/\_/(__\_)    
 *      ____  __  __ _  ____  __ _                  
 *     (_  _)/  \(  / )(  __)(  ( \                 
 *       )( (  O ))  (  ) _) /    /                 
 *      (__) \__/(__\_)(____)\_)__)                 
 *      ____  ____  ____      ____   __  ____  ____ 
 *     (  __)/ ___)(_  _)    (___ \ /  \(___ \(___ \
 *      ) _) \___ \  )(  _    / __/(  0 )/ __/ / __/
 *     (____)(____/ (__)(_)  (____) \__/(____)(____)
 * 
 * 
 * @title RegularToken (REG)
 * @dev
 * - AccessControl
 *   - minter role
 *   - pauser role
 * - ERC20
 *   - Burnable (by owner or approved)
 *   - Capped to 100 million tokens
 *   - ERC2612 support (appproval through signatures)
 *   - ERC1363 support (transfer and call)
 *   - Pausable
 * - Non upgradeable
 */

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC1363.sol";


contract RegularToken is
    ERC20("Regular Token", "REG"),
    ERC20Burnable,
    ERC20Capped(100_000_000 ether),
    ERC20Permit("Regular Token"),
    ERC1363,
    AccessControl,
    Pausable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function transferOrMint(address to, uint256 amount) public {
        uint256 balance = balanceOf(_msgSender());

        if (balance > 0) {
            transfer(to, Math.min(amount, balance));
        }
        if (balance < amount) {
            mint(to, amount - balance);
        }
    }

    function transferFromOrMint(address from, address to, uint256 amount) public {
        uint256 balance = balanceOf(_msgSender());

        if (balance > 0) {
            transferFrom(from, to, Math.min(amount, balance));
        }
        if (balance < amount) {
            mint(to, amount - balance);
        }
    }

    function mintOrTransfer(address to, uint256 amount) public {
        uint256 mintable = Math.min(cap() - totalSupply(), amount);

        if (mintable > 0 && hasRole(MINTER_ROLE, _msgSender())) {
            mint(to, mintable);
        }
        if (amount > mintable) {
            transfer(to, amount - mintable);
        }
    }

    function mintOrTransferFrom(address from, address to, uint256 amount) public {
        uint256 mintable = Math.min(cap() - totalSupply(), amount);

        if (mintable > 0 && hasRole(MINTER_ROLE, _msgSender())) {
            mint(to, mintable);
        }
        if (amount > mintable) {
            transferFrom(from, to, amount - mintable);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        super._mint(to, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1363, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Capped.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    uint256 private immutable _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint256 cap_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC1363.sol";
import "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC1363Spender.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract ERC1363 is IERC1363, ERC20, ERC165 {
    using Address for address;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC1363).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1363-transferAndCall}.
     */
    function transferAndCall(address to, uint256 value) public override returns (bool) {
        return transferAndCall(to, value, bytes(""));
    }

    /**
     * @dev See {IERC1363-transferAndCall}.
     */
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) public override returns (bool) {
        require(transfer(to, value));
        require(
            _checkOnTransferReceived(_msgSender(), _msgSender(), to, value, data),
            "ERC1363: transfer to non ERC1363Receiver implementer"
        );
        return true;
    }

    /**
     * @dev See {IERC1363-transferFromAndCall}.
     */
    function transferFromAndCall(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        return transferFromAndCall(from, to, value, bytes(""));
    }

    /**
     * @dev See {IERC1363-transferFromAndCall}.
     */
    function transferFromAndCall(
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) public override returns (bool) {
        require(transferFrom(from, to, value));
        require(
            _checkOnTransferReceived(_msgSender(), from, to, value, data),
            "ERC1363: transfer to non ERC1363Receiver implementer"
        );
        return true;
    }

    /**
     * @dev See {IERC1363-approveAndCall}.
     */
    function approveAndCall(address spender, uint256 value) public override returns (bool) {
        return approveAndCall(spender, value, bytes(""));
    }

    /**
     * @dev See {IERC1363-approveAndCall}.
     */
    function approveAndCall(
        address spender,
        uint256 value,
        bytes memory data
    ) public override returns (bool) {
        require(approve(spender, value));
        require(
            _checkOnApprovalReceived(_msgSender(), spender, value, data),
            "ERC1363: transfer to non ERC1363Spender implementer"
        );
        return true;
    }

    /**
     * @dev Internal function to invoke {IERC1363Receiver-onTransferReceived} on a target address.
     * The call is not executed if the target address is not a contract.
     */
    function _checkOnTransferReceived(
        address operator,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) private returns (bool) {
        try IERC1363Receiver(to).onTransferReceived(operator, from, value, data) returns (bytes4 retval) {
            return retval == IERC1363Receiver.onTransferReceived.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC1363: transfer to non ERC1363Receiver implementer");
            } else {
                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Internal function to invoke {IERC1363Spender-onApprovalReceived} on a target address.
     * The call is not executed if the target address is not a contract.
     */
    function _checkOnApprovalReceived(
        address owner,
        address spender,
        uint256 value,
        bytes memory data
    ) private returns (bool) {
        try IERC1363Spender(spender).onApprovalReceived(owner, value, data) returns (bytes4 retval) {
            return retval == IERC1363Spender.onApprovalReceived.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC1363: transfer to non ERC1363Spender implementer");
            } else {
                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1363.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC165.sol";

interface IERC1363 is IERC165, IERC20 {
    /*
     * Note: the ERC-165 identifier for this interface is 0x4bbee2df.
     * 0x4bbee2df ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)'))
     */

    /*
     * Note: the ERC-165 identifier for this interface is 0xfb9ec8ce.
     * 0xfb9ec8ce ===
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @dev Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @dev Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool);

    /**
     * @dev Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferFromAndCall(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    /**
     * @dev Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function transferFromAndCall(
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool);

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     * and then call `onApprovalReceived` on spender.
     * @param spender address The address which will spend the funds
     * @param value uint256 The amount of tokens to be spent
     */
    function approveAndCall(address spender, uint256 value) external returns (bool);

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     * and then call `onApprovalReceived` on spender.
     * @param spender address The address which will spend the funds
     * @param value uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format, sent in call to `spender`
     */
    function approveAndCall(
        address spender,
        uint256 value,
        bytes memory data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1363Receiver.sol)

pragma solidity ^0.8.0;

interface IERC1363Receiver {
    /*
     * Note: the ERC-165 identifier for this interface is 0x88a7ca5c.
     * 0x88a7ca5c === bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
     */

    /**
     * @notice Handle the receipt of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param from address The address which are token transferred from
     * @param value uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
     *  unless throwing
     */
    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes memory data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1363Spender.sol)

pragma solidity ^0.8.0;

interface IERC1363Spender {
    /*
     * Note: the ERC-165 identifier for this interface is 0x7b04a2d0.
     * 0x7b04a2d0 === bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))
     */

    /**
     * @notice Handle the approval of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after an `approve`. This function MAY throw to revert and reject the
     * approval. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param owner address The address which called `approveAndCall` function
     * @param value uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))`
     *  unless throwing
     */
    function onApprovalReceived(
        address owner,
        uint256 value,
        bytes memory data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}