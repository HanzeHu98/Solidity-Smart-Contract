// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract StockOfTheDay {

    struct Stock {
        // If you can limit the length to a certain number of bytes, 
        // always use one of bytes1 to bytes32 because they are much cheaper
        bytes32 name;   // short name (up to 32 bytes)
        int voteCount;   // number of accumulated votes
    }
    
    mapping(address => uint256) private lastVoteTime;    // Check if voted
    mapping(address => uint8[]) public todayStocks;     // list of stocks for the day
    mapping(address => uint256) private getStockTime;    
    address private owner;                              // Owner of the contract
    Stock[] public stocks;


    bytes32[] public stockNames = [
        bytes32("NIO"), bytes32("XPeng"), bytes32("Tesla"), bytes32("Amazon.com"), bytes32("Advanced Micro Devices"),
        bytes32("Ambez"), bytes32("Tilray Brands"), bytes32("Apple"), bytes32("Carnival Corporation"),
        bytes32("Ford Motor Company"), bytes32("Bank of America Corporation"), bytes32("Banco Bradesco"),
        bytes32("Farfetch Limited"), bytes32("Meta Platforms"), bytes32("NVIDIA Corporation"),
        bytes32("Canopy Growth Corporation"), bytes32("Nu Holdings Ltd."), bytes32("Alibaba Group Holding Limited"),
        bytes32("AMC Entertainment Holdings"), bytes32("Credit Suisse Group AG")
    ];

    /** 
     * @dev Create a new ballot to vote on teams
     */
    constructor() {
        owner = msg.sender;

        for (uint t = 0; t < stockNames.length; t++) {
            stocks.push(Stock({
                name: stockNames[t],
                voteCount: 0
            }));
        }
    }

    function notSameDay(uint256 pastTime, uint256 timeNow) private pure returns (bool){
        return pastTime / 60 / 60/ 24 != timeNow /60 / 60/ 24;
    }


    function setDailyStocks() public {
        require(notSameDay(getStockTime[msg.sender], block.timestamp), "You have already gotten your daily stocks today");
        uint8[5] memory indices = getRandomStockIndices(uint8(stockNames.length));
        todayStocks[msg.sender] = indices;
        getStockTime[msg.sender] = block.timestamp;
    }

    function getRandomStockIndices(uint8 bound) private view returns (uint8[5] memory){
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        //+ )
        uint8[5] memory output = [uint8(0), uint8(0),uint8(0),uint8(0),uint8(0)];
        
        uint index = 0;
        for (uint t = 0; t < 256/8; t++){
            if (index == 5){
                break;
            }
            uint8 numHash = uint8(randomHash) % bound;
            bool exist = false;
            for (uint i = 0; i < t; i++){
                if (output[i] == numHash) {
                    exist = true;
                }
            }
            if (!exist) {
                output[index] = numHash;
                index += 1;
            }
            randomHash = randomHash >> 8;
        }
        return output;
    }


    function getDailyStocks() public view returns (string[5] memory) {
        require(todayStocks[msg.sender].length != 0, "Please enter a stock in your daily stocks list");
        uint8[] memory indices = todayStocks[msg.sender];
        string[5] memory output = [
            string(abi.encodePacked(Strings.toString(indices[0]), stockNames[indices[0]])),
            string(abi.encodePacked(Strings.toString(indices[1]), stockNames[indices[1]])),
            string(abi.encodePacked(Strings.toString(indices[2]), stockNames[indices[2]])),
            string(abi.encodePacked(Strings.toString(indices[3]), stockNames[indices[3]])),
            string(abi.encodePacked(Strings.toString(indices[4]), stockNames[indices[4]]))
        ];
        return output;
    }

    /**
     * @dev Give your vote to team with specified number.
     * @param stockIndex is the name of the stock to vote for today
     */
    function vote(uint stockIndex) public {
        require(notSameDay(lastVoteTime[msg.sender], block.timestamp), "You have already voted today.");
        //require(todayStocks[msg.sender].length == 0, "Please get your daily stocks first.");
        
        bool validStockName = false;
        for (uint t = 0; t < todayStocks[msg.sender].length; t++){
            if (todayStocks[msg.sender][t] == stockIndex){
                validStockName = true;
            }
        }

        require(validStockName, "Please enter a stock in your daily stocks list");

        for (uint t = 0; t < stocks.length; t++){
            if (t == stockIndex){
                stocks[t].voteCount += 1;
                lastVoteTime[msg.sender] = block.timestamp;
            }
        }
    }

    /** 
     * @dev Calls bestFiveStocks() function to get the most voted 5 stocks
     * @return topFiveStocks the name of the winner
     */
    function bestFiveStocks() public view returns (string[5] memory) {
        require(
            msg.sender == owner,
            "Only owner can see vote totals"
        );
        uint8[5] memory indices = topFiveIndices(stocks);
        string[5] memory topFiveStocks = [  
            string(abi.encodePacked(stocks[indices[0]].name)),
            string(abi.encodePacked(stocks[indices[1]].name)),
            string(abi.encodePacked(stocks[indices[2]].name)),
            string(abi.encodePacked(stocks[indices[3]].name)),
            string(abi.encodePacked(stocks[indices[4]].name))
        ];
        return topFiveStocks;
    }


    function topFiveIndices(Stock[] memory arr) private pure returns (uint8[5] memory) {
        uint8[5] memory output = [
            0, 1 , 2, 3, 4
        ];
        uint8 i = 5;
        while (i < arr.length){
            uint8 least_index = 0;
            int voteLeast = arr[output[0]].voteCount;
            for (uint8 j = 1; j < 5; j ++){
                if (arr[output[j]].voteCount < voteLeast){
                    voteLeast = arr[output[j]].voteCount;
                    least_index = j;
                }
            }
            if (arr[i].voteCount > arr[output[least_index]].voteCount){
                output[least_index] = i;
            }
            i += 1;
        }
        return output;
    }

    

}
