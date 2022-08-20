// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.16;

import "AggregatorV3Interface.sol";

contract Fundme {
    address owner;

    AggregatorV3Interface public priceFeed;

// Nessa versÃ£o, vamos construir o priceFeed diretamente no constructor, 
//   e nÃ£o temos de criar uma interface em cada function.

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    mapping(address => uint256) public addtocash;

    address[] public funders;

    function Fund() public payable {
        addtocash[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function exchangeEth() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function amountUSD(uint256 _amount) public view returns (uint256) {
        uint256 exc = exchangeEth();
        uint256 total;
        total = exc * _amount;
        return total;
    }

    modifier Onlyowner() {
        require(msg.sender == owner, " HOLD ON SON");
        _;
    }

    function withdraw() public payable Onlyowner {
        payable(msg.sender).transfer(address(this).balance);
        uint256 cont;
        for (cont = 0; cont < funders.length; cont++) {
            addtocash[funders[cont]] = 0;
        }
    }
    //0x8A753747A1Fa494EC906cE90E9f37563A8AF630e -- Rinkeby Network
    /*
    - brownie init
    - importa contrato Fundme
    - brownie compile --> da erro pelo import, brownie n sabe de onde Ã© 
    - criar brownie-config.yaml
        - citar as dependencias e ordenar o compilador a interpretar o que Ã© esses imports, onde buscar.
        - estrutura da citaÃ§Ã£o: # <organization/repo>@<version>
        "
        dependencies:
            - smartcontractkit/[email protected] # ESPAÃ‡O ENTRE O TRAÃ‡O E O RESTO
            compiler:
                solc:
                    remappings:
                    - "@chainlink=smartcontractkit/[email protected]"  # ESPAÃ‡O ENTRE O TRAÃ‡O E O RESTO
        "
    - compile e veja novos arqs na pasta.
    - Criar script para deployar ctt
    - Crie nesse script tb a funÃ§Ã£o get account pra alterna entre redes ganache e testnets.
        - def get_account():
            if network.show_active() == "development":
                account = accounts[0]
            else:
                account = accounts.add(...)
            return account
     */
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}