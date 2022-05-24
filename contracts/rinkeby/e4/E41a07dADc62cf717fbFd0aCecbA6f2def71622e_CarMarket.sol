// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title CarMarket
 * @author Jelo
 * @notice CarMarket is a marketplace where people interested in cars can buy directly from the company.
 *         There is a problem however. An attacker can steal all the funds in the company's vault.
 *         The attack can only happen once. 
 *         Immediately a hack occurs, the company seizes sale of cars.
 */
contract CarMarket {

    // -- States --
    address public owner;
    bool public isHacked;
    address private carFactory;
    uint constant private CARCOST = 0.08 ether;

    struct Car {
        string color;
        string model;
        string plateNumber;
    }

    mapping(address => uint) private carCount;
    mapping(address => mapping(uint => Car)) public purchasedCars;

    /**
     * @notice Sets the car factory during deployment.
     * @param _factory A contract that is used to make crucial changes to the car company.
     */
    constructor(address _factory) {
        owner = msg.sender;
        carFactory = _factory;
    }

    // -- Modifiers --
    /**
     * @notice A modifier that authenticates the owner of the contract
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "CarMarket: !owner");
        _;
    }

    /**
     * @notice A modifier that checks if the contract haven't been hacked.
     */
    modifier notHacked {
        require(!isHacked, "Contract is hacked");
        _;
    }

    /**
     * @dev Enables a user to purchase a car
     * @param _color The color of the car to be purchased
     * @param _model The model of the car to be purchased
     * @param _plateNumber The plateNumber of the car to be purchased
    */
    function purchaseCar(string memory _color, string memory _model, string memory _plateNumber) notHacked external payable {
        //Ensure that the user has enough money to purchase a car
        require(msg.value == CARCOST);

        //Update the amount of cars the user has purchased. 
        uint _carCount = ++carCount[msg.sender];

        //Allocate a car to the user based on the user's specifications.
        purchasedCars[msg.sender][_carCount] = Car({
            color: _color,
            model: _model,
            plateNumber: _plateNumber
        });
    }

    /**
     * @dev Enables the owner of the contract to withdraw funds gotten from the purcahse of a car.
    */
    function withdrawFunds() external onlyOwner {

        //Fetches the balance of the contract(The money in the company's vault).
        uint _balance = address(this).balance;

        //Ensure that the vault isn't empty.
        require(_balance > 0, "CarMarket: Empty Vault");

        //Transfer the money out of the vault(contract) to the ownner
       (bool sent, ) = msg.sender.call{value: _balance}("");
       require(sent, "CarMarket: Error withdrawing funds");
    }

    /**
     * @dev A fallback function that delegates call to the CarFactory
    */
    fallback() notHacked external {
        carFactory.delegatecall(msg.data);
    }
}