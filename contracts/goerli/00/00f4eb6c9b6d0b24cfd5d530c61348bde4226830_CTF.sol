// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface Ilevel {
    function completeLevel(address studentContract) external payable returns(uint8);
    }	

contract CTF {

    address[] private addrArray; // Arrays for frontend . frontend looks up array then multicals get score.
    mapping(address => bool) addrLookUp; // Prevents address duplication
    uint8[] private levelArray;
    mapping(address => bool) whitelist;
    mapping(address => bool) Admin;
    mapping(address => bool) public voidAdrress; 
    mapping(uint8 => address) public levels; // LevelNumber => LevelContractAddress - For level contract lookup
    mapping(address => mapping(uint8 => uint8)) public scores; // StudentWalletAddress => Level => Score
    mapping(address => mapping(uint8 => uint256)) public gasUsed;
    mapping(address => string) public discordNames; // StudentWalletAddress => Name - For displaying name in React Dapp
    mapping(address => address) public solutions; // SolutionAdress => StudentAdress - Checks solutions is deployed by owner
    bool public canSubmit;
    bool public canRegister;
    bytes32 private passwordHash;
    address constant NULL = address(0);

    constructor() {
        Admin[msg.sender] = true;
    }

    modifier onlyAdmin(){
        require(Admin[msg.sender] == true, "Need to be Admin");
        _;
    }


    ///-------------------------------------------------------------------------------------///
    ///                 @notice - Registers user to give protocol access                    ///
    ///-------------------------------------------------------------------------------------///
    function register(string calldata userName, string calldata password) external {
        require(canRegister == true, "Registraton is closed");
        setDiscordName(userName);
        _joinWhiteList(password);
    }

    function setDiscordName(string calldata userName) public {
        discordNames[msg.sender] = userName;
        if(addrLookUp[msg.sender] == false) {
            addrArray.push(msg.sender);
            addrLookUp[msg.sender] = true;
        }
    }

    function _joinWhiteList(string calldata password) internal {
        require(keccak256(abi.encodePacked(password)) == passwordHash, "Check Password");
        whitelist[msg.sender] = true;
    }
    

    ///-------------------------------------------------------------------------------------///
    ///                       @notice - Submits and grades solution                         ///
    ///-------------------------------------------------------------------------------------///
    function submitSolution(uint8 levelNumber, address solutionAddress) external {
        require(canSubmit == true, "Exam Not Open/Contact Admin"); 
        require(levels[levelNumber] != NULL, "Invalid Level");
        require(bytes(discordNames[msg.sender]).length != 0, "Your Address is Not Registered");
        require(solutions[solutionAddress] == NULL || solutions[solutionAddress] == msg.sender, "msg.sender not owner of solution");
        solutions[solutionAddress] = msg.sender;
        Ilevel _level = Ilevel(levels[levelNumber]); // get level address
        uint256 preGas = gasleft();
        uint8 score = _level.completeLevel(solutionAddress); // submit solution to level address;
        uint256 gas = preGas - gasleft();
        // @dev If correct and score is personal best update score & gas
        if (scores[msg.sender][levelNumber] < score) {
            scores[msg.sender][levelNumber] = score;
            gasUsed[msg.sender][levelNumber] = gas;
        }
        // @dev If gas used is less and score the same update gas 
        if (scores[msg.sender][levelNumber] == score && gasUsed[msg.sender][levelNumber] > gas || gasUsed[msg.sender][levelNumber] == 0) {
            gasUsed[msg.sender][levelNumber] = gas;
        }
    }


    ///-------------------------------------------------------------------------------------///
    ///                         @notice - Admin only functions                              ///
    ///-------------------------------------------------------------------------------------///
    function setExamStatus(bool status) external onlyAdmin {
        canSubmit = status;
    }

    function setRegisterStatus(bool status) external onlyAdmin {
        canRegister = status;
    }

    function addLevel(address levelAddress, uint8 levelNumber) external onlyAdmin {
        require(levels[levelNumber] == NULL, "Already exsists, delete or use update"); 
        levels[levelNumber] = levelAddress;
        levelArray.push(levelNumber);
    }

    // @notice updates level address without changing level score data
    function updateLevel(address levelAddress, uint8 levelNumber) external onlyAdmin {
        require(levels[levelNumber] != NULL, "Can't update NULL level"); 
        levels[levelNumber] = levelAddress;
    }

    function setPassword(bytes32 password) external onlyAdmin {
        passwordHash = password;
    }

    function setAdmin(address admin, bool isAdmin) external onlyAdmin {
        require(admin != msg.sender, "Cannot set msg.sender admin"); // Must be at least 1 admin
        Admin[admin] = isAdmin;
    }

    function setVoidTag(address addr, bool isVoid) external onlyAdmin {
        voidAdrress[addr] = isVoid;
    }

    function removeLevel (uint8 level) external onlyAdmin{
        for (uint8 i = 0; i < levelArray.length; i++){
            if (levelArray[i] == level) {
                levelArray[i] = levelArray[levelArray.length - 1];    
                levelArray.pop();
            }
        }
        levels[level] = NULL;
        _deleteLevelData(level);
    }

    function _deleteLevelData(uint8 level) internal onlyAdmin{
        for (uint8 i = 0; i < addrArray.length; i++){
            scores[addrArray[i]][level] = 0;
        }
    }

    function removeAddress(address addr) external onlyAdmin{
        for (uint8 i = 0; i < addrArray.length; i++){
            if (addrArray[i] == addr) {
                addrArray[i] = addrArray[addrArray.length - 1];    
                addrArray.pop();
            }
        }
        whitelist[addr] = false;
        discordNames[addr] = "";
        _deleteAddressData(addr);
    }

    function _deleteAddressData(address addr) internal onlyAdmin{
        for (uint8 i = 0; i < levelArray.length;){
            scores[addr][levelArray[i]] = 0;
            i++;
        }
    }





    ///-------------------------------------------------------------------------------------///
    ///                 @notice - View functions for data lookups                           ///
    ///-------------------------------------------------------------------------------------///
    function getAddresses() public view returns (address[] memory) {
        return addrArray;
    }

    function getLevels() public view returns (uint8[] memory) {
      return levelArray;
    }

    function getScore(address addr, uint8 level) public view returns (address, string memory ,uint8, uint8, uint256) {
        return (
            addr,
            discordNames[addr],
            level,
            scores[addr][level],
            gasUsed[addr][level]
        );
    }
}