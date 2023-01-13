// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

struct NCAParams {
    string seed;
    string bg;
    string fg1;
    string fg2;
    string matrix;
    string activation;
    string rand;
    string mods;
}

interface INeuralAutomataEngine {
    function baseScript() external view returns(string memory);

    function parameters(NCAParams memory _params) external pure returns(string memory);

    function p5() external view returns(string memory);

    function script(NCAParams memory _params) external view returns(string memory);

    function page(NCAParams memory _params) external view returns(string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {NCAParams} from "./INeuralAutomataEngine.sol";

interface IZooOfNeuralAutomata {

    function updateEngine(address _engine) external;

    function updateContractURI(string memory _contractURI) external;

    function updateParams(uint256 _id, NCAParams memory _params) external;

    function updateMinter(uint256 _id, address _minter) external;

    function updateBurner(uint256 _id, address _burner) external;

    function updateBaseURI(uint256 _id, string memory _baseURI) external;

    function freeze(uint256 _id) external;

    function newToken(
        uint256 _id,
        NCAParams memory _params, 
        address _minter, 
        address _burner,
        string memory _baseURI
    ) external;

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external;

    function burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) external;
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IZooOfNeuralAutomata} from "../interfaces/IZooOfNeuralAutomata.sol";

contract Quaqs {
    uint256 constant maxSupply = 1000;
    uint256 constant price = 0.0314 ether;

    address public zona;
    uint256 public startTime;

    uint256 public sold;

    constructor(address _zona, uint256 _startTime) {
        zona = _zona;
        startTime = _startTime;
    }

    function mint(uint256 amount) external payable {
        require(startTime <= block.timestamp);
        require(msg.value >= price * amount);
        require(sold + amount <= maxSupply);

        sold += amount;

        IZooOfNeuralAutomata(zona).mint(msg.sender, 1, amount);
    }
}