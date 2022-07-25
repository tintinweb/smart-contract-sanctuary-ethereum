// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./BlackListUpgradeable.sol";
import "./AdvisorSupplyUpgradeable.sol";
import "./TeamSupplyUpgradeable.sol";
import "./SaleSupplyUpgradeable.sol";
import "./IRolaCoasterUpgradeable.sol";

contract RolaCoasterUpgradeable is ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, BlackListUpgradeable, AdvisorSupplyUpgradeable, TeamSupplyUpgradeable, SaleSupplyUpgradeable, IRolaCoasterUpgradeable{

    // Zero Address
    address constant ZERO_ADDRESS = address(0);

    // ROLA supply to treasury address
    uint256 public treasurySupplyRola;

    // Contract start time
    uint256 public startTime;

    // Address of the maintainer
    address private maintainer;

    // Address of the treasury
    address private treasury;

    // Initializer function for deploying the contract
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 rolaTokenRatePerUSDC,
        address maintainerAddress,
        address treasuryAddress,
        address teamAddress,
        address advisorAddress,
        address usdcContractAddress,
        uint256 starttime
    ) initializer external {
        require(maintainerAddress != ZERO_ADDRESS, "RolaCoaster: Cannot set maintainer address with Zero Address.");
        require(treasuryAddress != ZERO_ADDRESS, "RolaCoaster: Cannot set treasury address with Zero Address.");
        require(teamAddress != ZERO_ADDRESS, "RolaCoaster: Cannot set team address with Zero Address.");
        require(advisorAddress != ZERO_ADDRESS, "RolaCoaster: Cannot set advisory address with Zero Address.");
        __ERC20_init(tokenName, tokenSymbol);
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __BlackListEnabled_init();
        __VestingEnabled_init();
        __AdvisorSupplyEnabled_init(advisorAddress, starttime);
        __TeamSupplyEnabled_init(teamAddress, starttime);
        __SaleSupplyEnabled_init(treasuryAddress, usdcContractAddress, rolaTokenRatePerUSDC, decimals(), starttime);
        maintainer = maintainerAddress;
        treasury = treasuryAddress;
        // Change here
        startTime = starttime;
        treasurySupplyRola = 0;
        saleSupplyRola = 0;
        advisorSupplyRola = 0;
        teamSupplyRola = 0;
    }

    /// @dev This is the onlyMaintainer modifier. It is used by the backend to call contracts functions only by the maintainer address.

    modifier onlyMaintainer() {
        require(maintainer == _msgSender(), "RolaCoaster: caller is not the maintainer address");
        _;
    }

    /// @dev This is the mintRolaToTreasury function. It is used for minting ROLA tokens to the treasury address.
    /// @dev Only the maintainer can call this function.
    /// @param amountRola Amount of the ROLA tokens to be minted.

    function mintRolaToTreasury(uint256 amountRola) external override onlyMaintainer whenNotPaused nonReentrant {
        require(amountRola > 0, "RolaCoaster: ROLA amount should be greater than zero.");
        treasurySupplyRola += amountRola;
        _mint(treasury, amountRola);
        emit RolaMinted(treasury, amountRola);
    }

    /// @dev This is the mintRolaForAdvisor function. It is used for minting ROLA tokens to the advisor address.
    /// @dev Only the maintainer can call this function.

    function mintRolaForAdvisor() external override onlyMaintainer whenNotPaused nonReentrant {
        uint256 allowableMint = safeMintRolaForAdvisor() * (10 ** decimals());
        _mint(advisor, allowableMint);
        emit RolaMinted(advisor, allowableMint);
    }

    /// @dev This is the mintRolaForTeam function. It is used for minting ROLA tokens to the team address.
    /// @dev Only the maintainer can call this function.

    function mintRolaForTeam() external override onlyMaintainer whenNotPaused nonReentrant {
        uint256 allowableMint = safeMintRolaForTeam() * (10 ** decimals());
        _mint(team, allowableMint);
        emit RolaMinted(team, allowableMint);
    }

    /// @dev This is the mintRolaForTeam function. It is used for minting ROLA tokens from the maintainer address.
    /// @dev Only the maintainer can call this function.
    /// @param account Account to be minted with ROLA tokens.
    /// @param amountRola Amount of the ROLA tokens to be minted.

    function mintRolafromMaintainer(address account, uint256 amountRola) external override onlyMaintainer whenNotPaused nonReentrant whenNotBlackListedUser(account) {
        require(account != ZERO_ADDRESS, "RolaCoaster: Cannot mint Rola to Zero Address.");
        require(amountRola > 0, "RolaCoaster: ROLA amount should be greater than zero.");
        _mint(account, amountRola);
        emit RolaMinted(account, amountRola);
    }

    /// @dev This is the mintRolaforPublicSale function. It is used for minting ROLA tokens to the callers address.
    /// @param amountUSDC Amount of the USDC tokens to transfer to treasury for minting the ROLA token.
    
    function mintRolaforPublicSale(uint256 amountUSDC, uint256 saleTime) external override whenNotPaused nonReentrant whenNotBlackListedUser(_msgSender()) {
        // Change here
        uint256 currentEligibleRola = safeMintRolaforPublicSale(amountUSDC, saleTime);
        _mint(_msgSender(), currentEligibleRola);
        emit RolaMinted(_msgSender(), currentEligibleRola);
    }

    /// @dev This is the bulkMintRolaforPublicSale function. It is used mint the eligible ROLA tokens to the addresses in the sale.
    /// @dev Only the maintainer can call this function.
    /// @param saleId Sale Id to be bulk minted.

    function bulkMintRolaforPublicSale(uint8 saleId) external override whenNotPaused nonReentrant onlyMaintainer {
        SaleDetails memory saleDetails = saleIndexToSale[saleId];
        for(uint256 participantIndex = 0; participantIndex < saleDetails.saleParticipation; participantIndex++){
            ParticipationDetails memory participationDetails = userSaleParticipation[saleId][participantIndex];
            uint256 allowableMint = getAllowableRolaforPublicSale(saleId, participantIndex);
            if(allowableMint > 0){
                _mint(participationDetails.participatedAddress, allowableMint);
                emit RolaMinted(participationDetails.participatedAddress, allowableMint);
            }
        }
    }

    /// @dev This is the startSale function. It is used start the sale.
    /// @dev Only the maintainer can call this function.

    function startSale() external override whenNotPaused onlyMaintainer {
        uint8 saleIndex = safeStartSale();
        emit SaleStarted(saleIndex);
    }

    /// @dev This is the stopSale function. It is used stop the sale.
    /// @dev Only the maintainer can call this function.

    function stopSale() external override whenNotPaused onlyMaintainer {
        uint8 saleIndex = safeStopSale();
        emit SaleStopped(saleIndex);
    }

    /// @dev This is the mintRolaforPrivateSale function. It is used for minting ROLA tokens to the callers address.
    /// @param amountUSDC Amount of the USDC tokens to transfer to treasury for minting the ROLA token.
    /// @param saleId Sale Id of the private sale.

    function mintRolaforPrivateSale(uint256 amountUSDC, uint256 saleTime, uint8 saleId) external override whenNotPaused nonReentrant whenNotBlackListedUser(_msgSender()) onlyPrivateUser(saleId) {
        // Change here
        uint256 currentEligibleRola = safeMintRolaforPrivateSale(amountUSDC, saleTime, saleId);
        _mint(_msgSender(), currentEligibleRola);
        emit RolaMinted(_msgSender(), currentEligibleRola);
    }

    /// @dev This is the bulkMintRolaforPrivateSale function. It is used mint the eligible ROLA tokens to the addresses in the sale.
    /// @dev Only the maintainer can call this function.
    /// @param saleId Sale Id to be bulk minted.

    function bulkMintRolaforPrivateSale(uint8 saleId) external override whenNotPaused nonReentrant onlyMaintainer {
        PrivateSaleDetails memory privateSaleDetails = saleIndexToPrivateSale[saleId];
        for(uint256 participantIndex = 0; participantIndex < privateSaleDetails.participationIndex; participantIndex++){
            PrivateParticipationDetails memory privateParticipationDetails = privateSaleParticipation[saleId][participantIndex];
            uint256 allowableMint = getAllowableRolaforPrivateSale(saleId, participantIndex);
            if(allowableMint > 0){
                _mint(privateParticipationDetails.privateSaleAddress, allowableMint);
                emit RolaMinted(privateParticipationDetails.privateSaleAddress, allowableMint);
            }
        }
    }

    /// @dev This is the startPrivateSale function. It is used start the private sale.
    /// @dev Only the maintainer can call this function.

    function startPrivateSale(address privateAddress, uint256 rolaRateForSale, uint256 maxRolaAllowed, uint256 saleTime) external override whenNotPaused onlyMaintainer{
        // Change here
        uint8 privateSaleIndex = safeAddPrivateSaleDetails(privateAddress, rolaRateForSale, maxRolaAllowed, saleTime);
        emit PrivateSaleStarted(privateSaleIndex);
    }

    /// @dev This is the pausePrivateSale function. It is used to pause the private sale.
    /// @dev Only the maintainer can call this function.

    function pausePrivateSale(uint8 saleIndex) external override whenNotPaused onlyMaintainer {
        uint8 pausedPrivateSale = safePausePrivateSale(saleIndex);
        emit PrivateSalePaused(pausedPrivateSale);
    }

    /// @dev This is the unpausePrivateSale function. It is used to unpause the private sale.
    /// @dev Only the maintainer can call this function.

    function unpausePrivateSale(uint8 saleIndex) external override whenNotPaused onlyMaintainer {
        uint8 unpausedPrivateSale = safeUnpausePrivateSale(saleIndex);
        emit PrivateSaleUnpaused(unpausedPrivateSale);
    }

    /// @dev This is the airdropRola function. It is used by the owner to airdrop `quantity` number of ROLA tokens to the `assigned` address respectively.
    /// @dev Only the owner can call this function
    /// @param assigned The address to be airdropped
    /// @param quantity The amount of random tokens to be air dropped respectively

    function airdropRola(address[] memory assigned, uint256[] memory quantity) external override onlyOwner whenNotPaused nonReentrant {
        require(assigned.length == quantity.length, "RolaCoaster: Incorrect parameter length");
        for (uint8 index = 0; index < assigned.length; index++) {
            if(!_isBlackListUser(assigned[index])){
                _mint(assigned[index], quantity[index]);
                emit RolaMinted(assigned[index], quantity[index]);
            }
        }
    }

    /// @dev This is the updateMaintainerAddress function. It is used by the owner to update the maintainer address in the contract.
    /// @dev Only the owner can call this function
    /// @param newMaintainerAddress New maintainer address for the RolaCoaster contract 

    function updateMaintainerAddress(address newMaintainerAddress) external override onlyOwner whenNotPaused {
        require(maintainer != newMaintainerAddress,"RolaCoaster: The new maintainer address must be different from the old one");
        require(newMaintainerAddress != ZERO_ADDRESS, "RolaCoaster: Cannot set maintainer with Zero Address.");
        maintainer = newMaintainerAddress;
        emit NewMaintainAddressSet(newMaintainerAddress);
    }

    /// @dev This is the getMaintainerAddress function. It is used to get the maintainer address in the contract.

    function getMaintainerAddress() external view override returns (address) {
        return maintainer;
    }

    /// @dev This is the updateTreasuryAddress function. It is used by the owner to update the treasury address in the contract.
    /// @dev Only the maintainer can call this function
    /// @param newTreasuryAddress New treasury address for the RolaCoaster contract 

    function updateTreasuryAddress(address newTreasuryAddress) external override onlyMaintainer whenNotPaused {
        require(treasury != newTreasuryAddress,"RolaCoaster: The new treasury address must be different from the old one");
        require(newTreasuryAddress != ZERO_ADDRESS, "RolaCoaster: Cannot set treasury with Zero Address.");
        treasury = newTreasuryAddress;
        emit NewTreasuryAddressSet(newTreasuryAddress);
    }

    /// @dev This is the getTreasuryAddress function. It is used to get the treasury address in the contract.

    function getTreasuryAddress() external view override returns (address) {
        return treasury;
    }

    /// @dev This is the updateAdvisorAddress function. It is used by the owner to update the advisor address in the contract.
    /// @dev Only the maintainer can call this function
    /// @param newAdvisorAddress New advisor address for the RolaCoaster contract 

    function updateAdvisorAddress(address newAdvisorAddress) external override onlyMaintainer whenNotPaused {
        require(advisor != newAdvisorAddress,"RolaCoaster: The new advisor address must be different from the old one");
        require(newAdvisorAddress != ZERO_ADDRESS, "RolaCoaster: Cannot set advisor with Zero Address.");
        advisor = newAdvisorAddress;
        emit NewAdvisorAddressSet(newAdvisorAddress);
    }

    /// @dev This is the getAdvisorAddress function. It is used to get the advisor address in the contract.

    function getAdvisorAddress() external view override returns (address) {
        return advisor;
    }

    /// @dev This is the updateTeamAddress function. It is used by the owner to update the team address in the contract.
    /// @dev Only the maintainer can call this function
    /// @param newTeamAddress New team address for the RolaCoaster contract 

    function updateTeamAddress(address newTeamAddress) external override onlyMaintainer whenNotPaused {
        require(team != newTeamAddress,"RolaCoaster: The new team address must be different from the old one");
        require(newTeamAddress != ZERO_ADDRESS, "RolaCoaster: Cannot set team with Zero Address.");
        team = newTeamAddress;
        emit NewTeamAddressSet(newTeamAddress);
    }

    /// @dev This is the getTeamAddress function. It is used to get the team address in the contract.

    function getTeamAddress() external view override returns (address) {
        return team;
    }

    /// @dev This function would add an address to the blacklist mapping
    /// @dev Only the owner can call this function
    /// @param user The account to be added to blacklist

    function addToBlackList(address[] memory user) external override onlyOwner whenNotPaused returns (bool) {
        for (uint256 index = 0; index < user.length; index++) {
            if( user[index] != ZERO_ADDRESS){
                _addToBlackList(user[index]);
            }
        }
        return true;
    }

    /// @dev This function would remove an address from the blacklist mapping
    /// @dev Only the owner can call this function
    /// @param user The account to be removed from blacklist

    function removeFromBlackList(address[] memory user) external override onlyOwner whenNotPaused returns (bool) {
        for (uint256 index = 0; index < user.length; index++) {
            if( user[index] != ZERO_ADDRESS){
                _removeFromBlackList(user[index]);
            }
        }
        return true;
    }

    /// @dev This function would pause the contract
    /// @dev Only the owner can call this function

    function pause() external override onlyOwner {
        _pause();
    }

    /// @dev This function would unpause the contract
    /// @dev Only the owner can call this function

    function unpause() external override onlyOwner {
        _unpause();
    }   

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract VestingUpgradeable is Initializable {
    
    // ROLA CAP of 1Million Supply
    uint256 public constant ROLA_CAP = 1000000;

    // Hundred Percentage represntation
    uint32 constant HUNDRED_PERCENTAGE = 10000;

    // Number of seconds present per day
    uint256 constant SECONDS_PER_DAY = 86400;

    // Public sale allowed precentage of 15%
    uint16 constant PUBLIC_SALE_PERCENTAGE = 1500;

    // Advisor allowed precentage of 10%
    uint16 constant ADVISOR_PERCENTAGE = 1000;
    
    // Team allowed precentage of 12%
    uint16 constant TEAM_PERCENTAGE = 1200;

    function __VestingEnabled_init() internal onlyInitializing {
        __VestingEnabled_init_unchained();
    }

    function __VestingEnabled_init_unchained() internal onlyInitializing {
    }

    /// @dev This function return the max advisor supply till the days value passed
    /// @param daysPassed The number of days passed to get the result

    function getAdvisorSupplyForDays(uint32 daysPassed) public pure returns(uint32 supply){
        // Initial supply of 50K tokens
        supply = 50000;
        if(daysPassed > 0 && daysPassed < 366){
            uint32 daysPhase = daysPassed/10 + 1;
            // Supply of 833 to be added to initial for each 10 days phase
            uint32 additionalAmount = daysPhase * 833;
            if(daysPhase > 36)
                additionalAmount = 30000;
            supply += additionalAmount;
        }
        else if(daysPassed > 365){
            supply += 30000;
            daysPassed -= 365;
            uint32 daysPhase = daysPassed/10 + 1;
            // Supply of 547 to be added to initial for each 10 days phase
            uint32 additionalAmount = daysPhase * 547;
            if(daysPhase > 36)
                additionalAmount = 20000;
            supply += additionalAmount;
        }
    }

    /// @dev This function return the max team supply till the days value passed
    /// @param daysPassed The number of days passed to get the result

    function getTeamSupplyForDays(uint32 daysPassed) public pure returns(uint32 supply){
        // Initial supply of 50K tokens
        supply = 36000;
        if(daysPassed > 149 && daysPassed < 300){
            daysPassed -= 150;
            uint32 daysPhase = daysPassed/10 + 1;
            // Supply of 3200 to be added to initial for each 10 days phase
            uint32 additionalAmount = 3200 * daysPhase;
            supply += additionalAmount;
        }
        else if(daysPassed > 299 && daysPassed < 450){
            // Supply of 48000 to be added to initial for each 10 days phase
            supply += 48000;
        }
        else if(daysPassed > 449 && daysPassed < 650){
            supply += 48000;
            daysPassed -= 450;
            uint32 daysPhase = daysPassed/10 + 1;
            // Supply of 1700 to be added to initial for each 10 days phase
            uint32 additionalAmount = 1700 * daysPhase;
            supply += additionalAmount;
        }
        else if(daysPassed > 649){
            // Supply of 84000 to be added to initial for each 10 days phase
            supply += 84000;
        }
    }

    /// @dev This function return the max sale supply till the days value passed for the amount given
    /// @param amount The amount to be calculated for the public supply
    /// @param daysPassed The number of days passed to get the result

    function getPublicSupplyForDays(uint256 amount, uint32 daysPassed) public pure returns(uint256 supply){
        // Initial supply of 40% tokens for the amount passed
        supply = (4000 * amount) / HUNDRED_PERCENTAGE;
        if(daysPassed > 99 && daysPassed < 200){
            daysPassed -= 100;
            uint32 daysPhase = daysPassed/10 + 1;
            // Supply of 4% to be added to initial for each 10 days phase
            uint256 phaseMaxSupply = (400 * amount) / HUNDRED_PERCENTAGE;
            uint256 additionalAmount = phaseMaxSupply * daysPhase;
            supply += additionalAmount;
        }
        else if(daysPassed > 199 && daysPassed < 300){
            // Supply of 40% to be added to initial for each 10 days phase
            supply += (4000 * amount) / HUNDRED_PERCENTAGE;
        }
        else if(daysPassed > 299 && daysPassed < 400){
            supply += (4000 * amount) / HUNDRED_PERCENTAGE;
            daysPassed -= 300;
            uint32 daysPhase = daysPassed/10 + 1;
            // Supply of 2% to be added to initial for each 10 days phase
            uint256 phaseMaxSupply = (200 * amount) / HUNDRED_PERCENTAGE;
            uint256 additionalAmount = phaseMaxSupply * daysPhase;
            supply += additionalAmount;
        }
        else if(daysPassed > 399){
            // Return the full amount after completion of the vesting schedule
            supply = amount;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./VestingUpgradeable.sol";

contract TeamSupplyUpgradeable is Initializable, VestingUpgradeable {
    
    // ROLA supply to team address
    uint256 public teamSupplyRola;

    // Contract start time
    uint256 private startTime;

    // Address of the team
    address public team;

    function __TeamSupplyEnabled_init(address teamAddress, uint256 timeStart) internal onlyInitializing {
        __TeamSupply_init_unchained(teamAddress, timeStart);
    }

    function __TeamSupply_init_unchained(address teamAddress, uint256 timeStart) internal onlyInitializing {
        team = teamAddress;
        startTime = timeStart;
    }

    /// @dev This function return the max team supply till the days value passed

    function safeMintRolaForTeam() internal returns (uint256){
        uint256 maxTeamSupply = (ROLA_CAP * TEAM_PERCENTAGE)/HUNDRED_PERCENTAGE;
        require(maxTeamSupply > teamSupplyRola, "RolaCoaster: Team maximum supply reached.");
        uint256 currentDayPassed = (block.timestamp - startTime) / SECONDS_PER_DAY;
        uint256 currentAllowableMaximumMint = getTeamSupplyForDays(uint32(currentDayPassed));
        uint256 allowableMint = currentAllowableMaximumMint - teamSupplyRola;
        require(allowableMint > 0, "RolaCoaster: No amount can be minted as per vesting schedule.");
        teamSupplyRola += allowableMint;
        return allowableMint;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "./VestingUpgradeable.sol";

contract SaleSupplyUpgradeable is Initializable, VestingUpgradeable,ContextUpgradeable {

    // USDC contract instance
    IERC20Upgradeable public USDCContract;

    // Returns the decimals of the USDC token
    uint8 constant DECIMALS_USDC = 6;

    // Returns the decimals of the ROLA token
    uint8 private decimals;

    // Returns the next sale index
    uint8 public nextSaleIndex;

    // Returns the next private sale index
    uint8 public nextPrivateSaleIndex;

    // ROLA supply to the sales
    uint256 public saleSupplyRola;

    // Contract start time
    uint256 private startTime;

    // USDC token rate for public sale 
    uint256 public rolaRatePerUSDC;

    // Returns the total participation
    uint256 public totalParticipation;

    // Returns the next participation index for the active sale
    uint256 public nextParticipationIndexForSale;

    // Address of the treasury
    address private treasury;

    // Sale structure
    struct SaleDetails {
        bool saleStatus;
        uint8 saleIndex;
        uint256 totalTokenSold;
        uint256 saleStartTime;
        uint256 saleParticipation;
    }

    // Participation structure
    struct ParticipationDetails {
        address participatedAddress;
        uint256 participationId;
        uint256 amountBought;
        uint256 amountUSDCPaid;
        uint256 timeParticipated;
        uint256 amountReceived;
    }

    // Private sale structure
    struct PrivateSaleDetails {
        bool saleStatus;
        uint8 saleIndex;
        uint8 participationIndex;
        uint256 rolaRateForSale;
        uint256 maxRolaAllowed;
        uint256 rolaRedeemed;
        uint256 saleStartTime;
        address privateSaleAddress;
    }

    // Private participation structure
    struct PrivateParticipationDetails {
        uint8 saleIndex;
        uint8 participationId;
        uint256 amountBought;
        uint256 amountReceived;
        uint256 participationTime;
        address privateSaleAddress;
    }

    // Mapping of the sale ID to address to the tokens claimed
    mapping(uint8 => mapping(address => uint256)) public amountClaimedPerSale;
    
    // Mapping of the sale ID to sale details
    mapping(uint256 => SaleDetails) public saleIndexToSale;

    // Mapping of Sale ID to participation ID to its details
    mapping(uint256 => mapping(uint256 => ParticipationDetails)) public userSaleParticipation;

    // Mapping of the private sale ID to private sale details
    mapping(uint256 => PrivateSaleDetails) public saleIndexToPrivateSale;

    // Mapping of private sale ID to private participation ID to its details
    mapping(uint256 => mapping(uint256 => PrivateParticipationDetails)) public privateSaleParticipation;

    function __SaleSupplyEnabled_init(address treasuryAddress, address usdcContractAddress, uint256 rolaTokenRatePerUSDC, uint8 decimal, uint256 timeStart) internal onlyInitializing {
        __SaleSupply_init_unchained(treasuryAddress, usdcContractAddress, rolaTokenRatePerUSDC, decimal, timeStart);
    }

    function __SaleSupply_init_unchained(address treasuryAddress, address usdcContractAddress, uint256 rolaTokenRatePerUSDC, uint8 decimal, uint256 timeStart) internal onlyInitializing {
        USDCContract = IERC20Upgradeable(usdcContractAddress);
        treasury = treasuryAddress;
        startTime = timeStart;
        decimals = decimal;
        rolaRatePerUSDC = rolaTokenRatePerUSDC;
    }

    /// @dev This is the safeMintRolaforPublicSale function. It is used for minting ROLA tokens to the callers address.
    /// @param amountUSDC Amount of the USDC tokens to transfer to treasury for minting the ROLA token.
    /// @param saleTime The time of calling the function.
    
    function safeMintRolaforPublicSale(uint256 amountUSDC, uint256 saleTime) internal returns (uint256){
        require(nextSaleIndex > 0 && saleIndexToSale[nextSaleIndex - 1].saleStatus, "RolaCoaster: Currently no sale is active.");
        require(amountUSDC > 0, "RolaCoaster: USDC amount should be greater than zero.");
        require(USDCContract.balanceOf(_msgSender()) > amountUSDC, "RolaCoaster: Insufficient USDC tokens.");
        uint256 amountRola = (amountUSDC * rolaRatePerUSDC * ( 10 ** decimals)) / ((10 ** DECIMALS_USDC) * (10 ** DECIMALS_USDC));
        uint256 claimedAmountForSale = amountClaimedPerSale[nextSaleIndex - 1][_msgSender()] + amountRola;
        require(claimedAmountForSale <= 100 * (10 ** decimals), "RolaCoaster: ROLA amount exceeds 100 for active sale.");
        USDCContract.transferFrom(_msgSender(), treasury, amountUSDC);
        uint256 currentEligibleRola = addParticipationDetails(amountRola, amountUSDC, saleTime);
        amountClaimedPerSale[nextSaleIndex - 1][_msgSender()] += amountRola;
        saleSupplyRola += amountRola;
        return currentEligibleRola;
    }

    /// @dev This is the addParticipationDetails function. It is used for adding the participation details for the sale.
    /// @param amountRola Amount of the ROLA tokens to minted.
    /// @param amountUSDC Amount of the USDC tokens to transfer to treasury for minting the ROLA token.
    /// @param saleTime The time of calling the function.

    function addParticipationDetails(uint256 amountRola, uint256 amountUSDC, uint256 saleTime) internal returns (uint256){
        uint256 currentEligibleRola = getPublicSupplyForDays(amountRola, 0);
        ParticipationDetails memory participationDetails = ParticipationDetails({
            participatedAddress: _msgSender(),
            participationId: nextParticipationIndexForSale,
            amountBought: amountRola,
            amountUSDCPaid: amountUSDC,
            timeParticipated: saleTime,
            amountReceived: currentEligibleRola
        });
        userSaleParticipation[nextSaleIndex - 1][nextParticipationIndexForSale] = participationDetails;
        SaleDetails storage saleDetails = saleIndexToSale[nextSaleIndex - 1];
        saleDetails.saleParticipation = saleDetails.saleParticipation + 1;
        saleDetails.totalTokenSold = saleDetails.totalTokenSold + amountRola;
        totalParticipation++;
        nextParticipationIndexForSale++;
        return currentEligibleRola;
    }

    /// @dev This is the getAllowableRolaforPublicSale function. It is used for getting the eligible tokens in the provided sale.
    /// @param saleId The sale ID to get the result.
    /// @param participantIndex The participation index in the sale.

    function getAllowableRolaforPublicSale(uint8 saleId, uint256 participantIndex) internal returns (uint256){
        ParticipationDetails storage participationDetails = userSaleParticipation[saleId][participantIndex];
        uint256 currentDayPassed = (block.timestamp - participationDetails.timeParticipated) / SECONDS_PER_DAY;
        uint256 currentAllowableMaximumMint = getPublicSupplyForDays(participationDetails.amountBought, uint16(currentDayPassed));
        uint256 allowableMint = currentAllowableMaximumMint - participationDetails.amountReceived;
        participationDetails.amountReceived = currentAllowableMaximumMint;
        return allowableMint;
    }

    /// @dev This is the safeStartSale function. It is used start the sale.

    function safeStartSale() internal returns (uint8){
        if(nextSaleIndex > 0){
            SaleDetails storage previousSaleDetails = saleIndexToSale[nextSaleIndex - 1];
            previousSaleDetails.saleStatus = false;
        }
        SaleDetails memory saleDetails = SaleDetails({
            saleStatus: true,
            saleIndex: nextSaleIndex,
            totalTokenSold: 0,
            saleStartTime: block.timestamp,
            saleParticipation: 0
        });
        saleIndexToSale[nextSaleIndex] = saleDetails;
        nextParticipationIndexForSale = 0;
        nextSaleIndex++;
        return nextSaleIndex - 1;
    }

    /// @dev This is the safeStopSale function. It is used stop the sale.
    
    function safeStopSale() internal returns (uint8){
        require(nextSaleIndex > 0 && saleIndexToSale[nextSaleIndex - 1].saleStatus, "RolaCoaster: Currently no sale is active.");
        SaleDetails storage previousSaleDetails = saleIndexToSale[nextSaleIndex - 1];
        previousSaleDetails.saleStatus = false;
        return previousSaleDetails.saleIndex;
    }

    /// @dev This is the safeMintRolaforPrivateSale function. It is used for minting ROLA tokens to the callers address.
    /// @param amountUSDC Amount of the USDC tokens to transfer to treasury for minting the ROLA token.
    /// @param saleTime The time of calling the function.
    /// @param saleId The private sale ID.

    function safeMintRolaforPrivateSale(uint256 amountUSDC, uint256 saleTime, uint8 saleId) internal returns (uint256){
        PrivateSaleDetails storage privateSaleDetails = saleIndexToPrivateSale[saleId];
        require(nextPrivateSaleIndex > 0 && privateSaleDetails.saleStatus, "RolaCoaster: Private sale does not exist.");
        require(amountUSDC > 0, "RolaCoaster: USDC amount should be greater than zero.");
        require(USDCContract.balanceOf(_msgSender()) > amountUSDC, "RolaCoaster: Insufficient USDC tokens.");
        uint256 amountRola = (amountUSDC * privateSaleDetails.rolaRateForSale * ( 10 ** decimals)) / ((10 ** DECIMALS_USDC) * (10 ** DECIMALS_USDC));
        require(privateSaleDetails.maxRolaAllowed >= privateSaleDetails.rolaRedeemed + amountRola, "RolaCoaster: Cannot mint greater than maximum allowed Rola amount.");
        USDCContract.transferFrom(_msgSender(), treasury, amountUSDC);
        uint256 currentEligibleRola = addPrivateParticipationDetails(amountRola, saleId, saleTime);
        privateSaleDetails.rolaRedeemed = privateSaleDetails.rolaRedeemed + currentEligibleRola;
        privateSaleDetails.participationIndex = privateSaleDetails.participationIndex + 1; 
        saleSupplyRola += amountRola;
        return currentEligibleRola;
    }

    /// @dev This is the addPrivateParticipationDetails function. It is used for adding the participation details for the private sale.
    /// @param amountRola Amount of the ROLA tokens to minted.
    /// @param saleId The private sale ID.
    /// @param saleTime The time of calling the function.

    function addPrivateParticipationDetails(uint256 amountRola, uint8 saleId, uint256 saleTime) internal returns (uint256){
        uint256 currentEligibleRola = getPublicSupplyForDays(amountRola, 0);
        PrivateSaleDetails memory privateSaleDetails = saleIndexToPrivateSale[saleId];
        PrivateParticipationDetails memory participationDetails = PrivateParticipationDetails({
            saleIndex: saleId,
            participationId: privateSaleDetails.participationIndex,
            amountBought: amountRola,
            amountReceived: currentEligibleRola,
            participationTime: saleTime,
            privateSaleAddress: _msgSender()            
        });
        privateSaleParticipation[saleId][privateSaleDetails.participationIndex] = participationDetails;
        totalParticipation++;
        return currentEligibleRola;
    }

    /// @dev This is the getAllowableRolaforPrivateSale function. It is used for getting the eligible tokens in the provided private sale.
    /// @param saleId The sale ID to get the result.
    /// @param participantIndex The participation index in the private sale.

    function getAllowableRolaforPrivateSale(uint8 saleId, uint256 participantIndex) internal returns (uint256){
        PrivateParticipationDetails storage privateParticipationDetails = privateSaleParticipation[saleId][participantIndex];
        uint256 currentDayPassed = (block.timestamp - privateParticipationDetails.participationTime) / SECONDS_PER_DAY;
        uint256 currentAllowableMaximumMint = getPublicSupplyForDays(privateParticipationDetails.amountBought, uint16(currentDayPassed));
        uint256 allowableMint = currentAllowableMaximumMint - privateParticipationDetails.amountReceived;
        privateParticipationDetails.amountReceived = currentAllowableMaximumMint;
        return allowableMint;
    }

    /// @dev This is the safeAddPrivateSaleDetails function. It is used start the private sale.
    /// @param privateAddress The address of the participating address.
    /// @param rolaRateForSale The rate of ROLA with respect to USDC in the private sale.
    /// @param maxRolaAllowed The maximum ROLA tokens allowed in the private sale.
    /// @param saleTime The time of calling the function.

    function safeAddPrivateSaleDetails(address privateAddress, uint256 rolaRateForSale, uint256 maxRolaAllowed, uint256 saleTime) internal returns (uint8){
        require(rolaRateForSale > 0, "RolaCoaster: ROLA rate should be greater than zero.");
        require(maxRolaAllowed > 0, "RolaCoaster: Max ROLA amount should be greater than zero.");
        PrivateSaleDetails memory privateSaleDetails = PrivateSaleDetails({
            saleStatus: true,
            saleIndex: nextPrivateSaleIndex,
            participationIndex: 0,
            rolaRateForSale: rolaRateForSale,
            maxRolaAllowed: maxRolaAllowed,
            rolaRedeemed: 0,
            saleStartTime: saleTime,
            privateSaleAddress: privateAddress
        });
        saleIndexToPrivateSale[nextPrivateSaleIndex] = privateSaleDetails;
        nextPrivateSaleIndex++;
        return nextPrivateSaleIndex - 1;
    }

    /// @dev This is the safePausePrivateSale function. It is used pause the private sale.
    /// @param saleIndex The private sale ID.

    function safePausePrivateSale(uint8 saleIndex) internal returns (uint8){
        require(nextPrivateSaleIndex > 0, "RolaCoaster: Private sale does not exist.");
        PrivateSaleDetails storage privateSaleDetails = saleIndexToPrivateSale[saleIndex];
        require(privateSaleDetails.saleStartTime > 0 && privateSaleDetails.saleStatus, "RolaCoaster: Private sale already paused.");
        privateSaleDetails.saleStatus = false;
        return saleIndex;
    }

    /// @dev This is the safeUnpausePrivateSale function. It is used unpause the private sale.
    /// @param saleIndex The private sale ID.

    function safeUnpausePrivateSale(uint8 saleIndex) internal returns (uint8){
        require(nextPrivateSaleIndex > 0, "RolaCoaster: Private sale does not exist.");
        PrivateSaleDetails storage privateSaleDetails = saleIndexToPrivateSale[saleIndex];
        require(privateSaleDetails.saleStartTime > 0 && !privateSaleDetails.saleStatus, "RolaCoaster: Private sale already unpaused.");
        privateSaleDetails.saleStatus = true;
        return saleIndex;
    }

    // Modifier to check address belongs to the private sale
    /// @param saleId The private sale ID.

    modifier onlyPrivateUser(uint8 saleId) {
        PrivateSaleDetails memory privateSaleDetails = saleIndexToPrivateSale[saleId];
        require(privateSaleDetails.privateSaleAddress == _msgSender(), "RolaCoaster: caller is not the private user address.");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev Interface of the RolaCoaster ERC1155 token implementation.
 * @author The Systango Team
 */

interface IRolaCoasterUpgradeable {

    /**
     * @dev Event generated when a new Maintainer is set
     */
    event NewMaintainAddressSet(address newMaintainerAddress);

    /**
     * @dev Event generated when a new Treasury is set
     */
    event NewTreasuryAddressSet(address newTreasuryAddress);

    /**
     * @dev Event generated when a new Advisor is set
     */
    event NewAdvisorAddressSet(address newAdvisorAddress);

    /**
     * @dev Event generated when a new Team is set
     */
    event NewTeamAddressSet(address newTeamAddress);

    /**
     * @dev Event generated when ROLA tokens are minted
     */
    event RolaMinted(address account, uint256 amount);
    
    /**
     * @dev Event generated when sale is started
     */
    event SaleStarted(uint8 saleIndex);

    /**
     * @dev Event generated when sale is stopped
     */
    event SaleStopped(uint8 saleIndex);

    /**
     * @dev Event generated when private sale is started
     */
    event PrivateSaleStarted(uint8 saleIndex);

    /**
     * @dev Event generated when private sale is paused
     */
    event PrivateSalePaused(uint8 saleIndex);

    /**
     * @dev Event generated when private sale is unpaused
     */
    event PrivateSaleUnpaused(uint8 saleIndex);

    /**
     * @dev Mint the ROLA tokens to the treasury
     */
    function mintRolaToTreasury(uint256 amountRola) external;

    /**
     * @dev Mint the ROLA tokens to the advisor
     */
    function mintRolaForAdvisor() external;

    /**
     * @dev Mint the ROLA tokens to the team
     */
    function mintRolaForTeam() external;

    /**
     * @dev Mint the ROLA tokens from the maintainer
     */
    function mintRolafromMaintainer(address account, uint256 amountRola) external;

    /**
     * @dev Mint the ROLA tokens to the account
     */
    function mintRolaforPublicSale(uint256 amountUSDC, uint256 saleTime) external;

    /**
     * @dev Mint the ROLA tokens for the sale ID for all the eligible tokens
     */
    function bulkMintRolaforPublicSale(uint8 saleId) external;

    /**
     * @dev Start the sale
     */
    function startSale() external;

    /**
     * @dev Stop the sale
     */
    function stopSale() external;

    /**
     * @dev Mint the ROLA tokens to the account in private sale
     */
    function mintRolaforPrivateSale(uint256 amountUSDC, uint256 saleTime, uint8 saleId) external;

    /**
     * @dev Mint the ROLA tokens for the private sale ID for all the eligible tokens
     */
    function bulkMintRolaforPrivateSale(uint8 saleId) external;

    /**
     * @dev Start the private sale
     */
    function startPrivateSale(address privateAddress, uint256 rolaRateForSale, uint256 maxRolaAllowed, uint256 saleTime) external;

    /**
     * @dev Pause the private sale
     */
    function pausePrivateSale(uint8 saleIndex) external;

    /**
     * @dev Unpause the private sale
     */
    function unpausePrivateSale(uint8 saleIndex) external;

    /**
     * @dev Airdrop the ROLA tokens to a set of users
     */
    function airdropRola(address[] memory assigned, uint256[] memory quantity) external;

    /**
     * @dev Set the maintainer address of the contract
     */
    function updateMaintainerAddress(address newMaintainerAddress) external;

    /**
     * @dev Get the maintainer address of the contract
     */
    function getMaintainerAddress() external view returns (address);

    /**
     * @dev Set the treasury address of the contract
     */
    function updateTreasuryAddress(address newTreasuryAddress) external;

    /**
     * @dev Get the treasury address of the contract
     */
    function getTreasuryAddress() external view returns (address);

    /**
     * @dev Set the advisor address of the contract
     */
    function updateAdvisorAddress(address newAdvisorAddress) external;

    /**
     * @dev Get the advisor address of the contract
     */
    function getAdvisorAddress() external view returns (address);

    /**
     * @dev Set the team address of the contract
     */
    function updateTeamAddress(address newTeamAddress) external;

    /**
     * @dev Get the team address of the contract
     */
    function getTeamAddress() external view returns (address);

    /**
     * @dev Adds the account to blacklist
     */
    function addToBlackList(address[] memory _user) external returns (bool);

    /**
     * @dev Removes the account from blacklist
     */
    function removeFromBlackList(address[] memory _user) external returns (bool);

    /**
     * @dev Pause the contract
     */
    function pause() external;

    /**
     * @dev Unpause the contract
     */
    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title Stablecoin contract with the role management for coin issuance
/// @author The Systango Team

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BlackListUpgradeable is Initializable {

    // Mapping between the address and boolean for blacklisting
    mapping (address => bool) public blackList;

    // Event to trigger the addition of address to blacklist mapping
    event AddedToBlackList(address _user);

    // Event to trigger the removal of address from blacklist mapping
    event RemovedFromBlackList(address _user);

    function __BlackListEnabled_init() internal onlyInitializing {
        __BlackListEnabled_init_unchained();
    }

    function __BlackListEnabled_init_unchained() internal onlyInitializing {
    }
    
    // This function would add an address to the blacklist mapping
    /// @param _user The account to be added to blacklist

    function _addToBlackList(address _user) internal virtual returns (bool) {
        blackList[_user] = true;
        emit AddedToBlackList(_user);
        return true;
    }

    // This function would remove an address from the blacklist mapping
    /// @param _user The account to be removed from blacklist

    function _removeFromBlackList(address _user) internal virtual returns (bool) {
        delete blackList[_user];
        emit RemovedFromBlackList(_user);
        return true;
    }

    // This function would check an address from the blacklist mapping
    /// @param _user The account to be checked from blacklist mapping

    function _isBlackListUser(address _user) internal virtual returns (bool){
        return blackList[_user];
    }

    // Modifier to check address from the blacklist mapping
    /// @param _user The account to be checked from blacklist mapping

    modifier whenNotBlackListedUser(address _user) {
        require(!_isBlackListUser(_user), "RolaCoaster: This address is in blacklist");
        _;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./VestingUpgradeable.sol";

contract AdvisorSupplyUpgradeable is Initializable, VestingUpgradeable {
    
    // ROLA supply to advisor address
    uint256 public advisorSupplyRola;

    // Contract start time
    uint256 private startTime;

    // Address of the advisor
    address public advisor;

    function __AdvisorSupplyEnabled_init(address advisorAddress, uint256 timeStart) internal onlyInitializing {
        __AdvisorSupply_init_unchained(advisorAddress, timeStart);
    }

    function __AdvisorSupply_init_unchained(address advisorAddress, uint256 timeStart) internal onlyInitializing {
        advisor = advisorAddress;
        startTime = timeStart;
    }

    /// @dev This function return the max advisor supply till the days value passed

    function safeMintRolaForAdvisor() internal returns (uint256){
        uint256 maxAdvisorSupply = (ROLA_CAP * ADVISOR_PERCENTAGE)/HUNDRED_PERCENTAGE;
        require(maxAdvisorSupply > advisorSupplyRola, "RolaCoaster: Advisor maximum supply reached.");
        uint256 currentDayPassed = (block.timestamp - startTime) / SECONDS_PER_DAY;
        uint256 currentAllowableMaximumMint = getAdvisorSupplyForDays(uint32(currentDayPassed));
        uint256 allowableMint = currentAllowableMaximumMint - advisorSupplyRola;
        require(allowableMint > 0, "RolaCoaster: No amount can be minted as per vesting schedule.");
        advisorSupplyRola += allowableMint;
        return allowableMint;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}