// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Green area contract.
 * @notice This contract can be used to automatically pay someone you assign
 * to solve a problem within your green area.
 */
contract GreenArea {
    /**
     * @dev GPS coordinates stored as int32.
     */
    struct Coordinates {
        int32 latitude;
        int32 longitude;
    }

    /**
     * @dev Green area metadata.
     */
    struct GreenAreaData {
        uint256 id;
        string name;
        Coordinates coordinates;
    }

    /**
     * @dev Problem types that can be solved within the green area.
     */
    enum ProblemType {
        MALFUNCTIONING_SENSOR
    }

    /**
     * @dev Maps an address to a list of green areas.
     */
    mapping(address => GreenAreaData[]) ownerToGreenAreas;

    /**
     * @dev Maps the ID of a green area to the address of its owner.
     */
    mapping(uint256 => address) greenAreaIdToOwner;

    /**
     * @dev Maps the ID of a green area to another map of problem type to
     * problem solver (agent) address.
     */
    mapping(uint256 => mapping(ProblemType => address)) problemResolutionAuthorizations;

    /**
     * @dev Maps the ID of a green area to another map of problem type to
     * reward amount
     */
    mapping(uint256 => mapping(ProblemType => uint256)) problemResolutionRewards;

    /**
     * @dev Maps the address of agent to authorized green areas.
     */
    mapping(address => uint256[]) agentAuthorizedGreenAreas;

    /**
     * @dev Stores the next ID that willbe assigned when a green area is registered.
     */
    uint256 nextGreenAreaId;

    /**
     * @notice Register a new green area with its name and coordinates.
     */
    function registerGreenArea(
        string memory name,
        int32 latitude,
        int32 longitude
    ) public returns (uint256) {
        uint256 id = nextGreenAreaId;

        ownerToGreenAreas[msg.sender].push(
            GreenAreaData(id, name, Coordinates(latitude, longitude))
        );

        greenAreaIdToOwner[id] = msg.sender;

        nextGreenAreaId++;

        return id;
    }

    /**
     * @dev Allow only the owner of the green area to execute a function.
     */
    modifier onlyAreaOwner(uint256 greenAreaId) {
        require(
            greenAreaIdToOwner[greenAreaId] == msg.sender,
            "You are not the owner of this green area"
        );

        _;
    }

    /**
     * @dev Only previously authorized agent can solve a problem and receive payment.
     */
    modifier onlyAuthorizedAgent(uint256 greenAreaId, ProblemType problemType) {
        require(
            msg.sender ==
                problemResolutionAuthorizations[greenAreaId][problemType],
            "You are not authorized to receive payment"
        );

        _;
    }

    /**
     * @notice Get all your green areas.
     * @dev The return type is a list of tuples, the elements of the tuple
     * are sorted like they were declared in the struct.
     */
    function getGreenAreas(address owner)
        public
        view
        returns (GreenAreaData[] memory)
    {
        return ownerToGreenAreas[owner];
    }

    function getAuthorizedAreas(address agent)
        public
        view
        returns (uint256[] memory)
    {
        return agentAuthorizedGreenAreas[agent];
    }

    /**
     * @notice Set the address of the agent as authorized to solve the given
     * problem type in the green area.
     */
    function authorizeAgentToSolveProblem(
        address agent,
        uint256 greenAreaId,
        ProblemType problemType,
        uint256 reward
    ) public payable onlyAreaOwner(greenAreaId) {
        require(
            msg.value >= reward,
            "The amount sent is not enough to pay the given reward to the agent"
        );
        if (
            problemResolutionAuthorizations[greenAreaId][problemType] != agent
        ) {
            // Only add once, if the agent was added the condition will be false
            agentAuthorizedGreenAreas[agent].push(greenAreaId);
        }
        problemResolutionAuthorizations[greenAreaId][problemType] = agent;
        problemResolutionRewards[greenAreaId][problemType] = reward;
    }

    /**
     * @notice Get the address of the currently authorized agent to solve
     * the given problem type in the given green area.
     */
    function getAuthorizedAgent(uint256 greenAreaId, ProblemType problemType)
        public
        view
        onlyAreaOwner(greenAreaId)
        returns (address)
    {
        return problemResolutionAuthorizations[greenAreaId][problemType];
    }

    /**
     * @notice Mark problem as solved and receive payment.
     */
    function problemSolved(uint256 greenAreaId, ProblemType problemType)
        public
        payable
        onlyAuthorizedAgent(greenAreaId, problemType)
    {
        payable(msg.sender).transfer(
            problemResolutionRewards[greenAreaId][problemType]
        );
        delete problemResolutionAuthorizations[greenAreaId][problemType];
        delete problemResolutionRewards[greenAreaId][problemType];

        // Remove area from authorized areas for the agent
        for (uint256 i = 0; i < agentAuthorizedGreenAreas[msg.sender].length; i++) {
            if (agentAuthorizedGreenAreas[msg.sender][i] == greenAreaId) {
                agentAuthorizedGreenAreas[msg.sender][i] = agentAuthorizedGreenAreas[msg.sender][agentAuthorizedGreenAreas[msg.sender].length - 1];
                agentAuthorizedGreenAreas[msg.sender].pop();
                break;
            }
        }
    }
}