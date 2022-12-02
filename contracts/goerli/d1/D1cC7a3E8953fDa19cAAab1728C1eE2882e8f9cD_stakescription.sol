// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract stakescription {
    address owner; // us as NCS Owner(contract Owner)

    uint256 planIdCounter = 1; // Id counter for Plan details
    uint256[] public planIdArray; // Id array for Plan details

    uint256[] emptyPlanCells; //empth cell for plans array

    constructor() {
        owner = msg.sender;
    }

    /// @notice struck for User details
    struct userDetails {
        string name;
        string emailId;
        uint256 mobileNumber;
        string userImage;
    }

    /// @notice struck for plan details
    struct planDetails {
        string name;
        uint256 price;
        uint256 timePeriod;
        string planImage;
    }

    /// @notice mapping for handeling User's data (userDataMapping)
    mapping(address => userDetails) public userDataMapping;
    /// @notice mapping for handeling plan's data (planDataMapping)
    mapping(uint256 => planDetails) public planDataMapping;

    /// @notice mapping for user to plan (which user is subscribed to which plan)
    mapping(address => uint256[]) public userToPlanMapping;

    /// @notice mapping to check user's plan is active or not
    mapping(address => mapping(uint256 => bool)) public isUserPlanActive;

    /// @notice mapping for user's stake
    mapping(address => uint) public stakeMapping;

    

    ///@notice Function to add user. (signUp) (adding user's data to blockchain)
    function addUser(
        string memory _name,
        string memory _emailId,
        uint256 _mobileNumber,
        string memory _userImage
    ) public {
        userDetails memory user = userDetails(_name, _emailId, _mobileNumber, _userImage);
        userDataMapping[msg.sender] = user;
    }

    ///@notice Function to get User Details
    function getUserDetails(address _userId)
        public
        view
        returns (userDetails memory)
    {
        return userDataMapping[_userId];
    }

    ///@notice function to delete user(used to delete your OWN account)
    function deleteUser() public {
        delete userDataMapping[msg.sender];
    }


    /// @notice Function to edit users' name
    function editUserName(string memory _name) public {
        userDetails memory user = userDataMapping[msg.sender];
        user.name = _name;
        userDataMapping[msg.sender] = user;
    }
    /// @notice Function to edit users' email
    function editUserEmail(string memory _emailId) public {
        userDetails memory user = userDataMapping[msg.sender];
        user.emailId = _emailId;
        userDataMapping[msg.sender] = user;
    }
    /// @notice Function to edit users' mobileNumber
    function editUserMobileNumber(uint256 _mobileNumber) public {
        userDetails memory user = userDataMapping[msg.sender];
        user.mobileNumber = _mobileNumber;
        userDataMapping[msg.sender] = user;
    }

    /// @notice Function to edit users' Image
    function editUserImage(string memory _userImage) public {
        userDetails memory user = userDataMapping[msg.sender];
        user.userImage = _userImage;
         userDataMapping[msg.sender] = user;
    }

    ///@notice Function to Add Plan
    function addPlan(
        string memory _name,
        uint256 _price,
        uint256 _timePeriod,
        string memory _planImage
    ) public {
        require(msg.sender == owner, "only owner can add plans");
        if (emptyPlanCells.length != 0) {
            planIdCounter = emptyPlanCells[emptyPlanCells.length - 1];
            emptyPlanCells.pop();
        } else {
            planIdCounter = planIdArray.length;
            planIdCounter++;
            planIdArray.push(planIdCounter);
        }
        planDetails memory plan = planDetails(_name, _price, _timePeriod, _planImage);
        planDataMapping[planIdCounter] = plan;
    }

    ///@notice function to delete plan
    function deletePlan(uint256 _planId) public {
        emptyPlanCells.push(_planId);
        planDetails memory plan = planDetails("", 0, 0,"");
        planDataMapping[_planId] = plan;
    }
    
    /// @notice Function to count number of plans
    function countPlan() public view returns(uint256){
        return planIdArray.length;
    }


    ///@notice function to get plan details
    function getPlanDetails(uint256 _planId)
        public
        view
        returns (planDetails memory)
    {
        return planDataMapping[_planId];
    }

    /// @notice function to subscribe to any plan
    function subscribe(address _userId, uint256 _planId) public payable {
        uint256 planPrice = planDataMapping[_planId].price;
        require(msg.value >= planPrice,"please provide proper value");
        stakeMapping[msg.sender] += msg.value;
        isUserPlanActive[_userId][_planId] = true;
        userToPlanMapping[_userId].push(_planId);
    }

    // function planPrice(uint256 _planId) public view returns(uint) {
    //     return planDataMapping[_planId].price;
    // }

    /// @notice function to show user's subscribed plans
    function showUserPlans(address _userId)
        public
        view
        returns (uint256[] memory)
    {
        return userToPlanMapping[_userId];
    }

    ///@notice function to deActivate any plan
    function deActivate(address _userId, uint256 _planId) public {
        isUserPlanActive[_userId][_planId] = false;
    }

    function showUserActivePlans(address _userId,uint256 _planId) public view returns(bool) {
        return isUserPlanActive[_userId][_planId];
    }

}