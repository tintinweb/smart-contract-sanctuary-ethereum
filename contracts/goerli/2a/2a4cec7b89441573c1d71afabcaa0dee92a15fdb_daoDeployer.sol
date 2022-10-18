// SPDX-License-Identifier: MIT
    pragma solidity^0.8.0;

    import './_voting.sol';

    contract daoDeployer {

        
        struct Dao{

            string daoName;
            myDao daoNew;
            address creator;
        }

        Dao[] public daos;


        function createDao(string memory _name) public {

            myDao newDao = new myDao();
            daos.push(Dao({
                daoName : _name,
                daoNew : newDao,
                creator : msg.sender
            }));

        }

        function viewDao(uint id) public view returns(myDao) {

            return (daos[id].daoNew);
            
        }

    }