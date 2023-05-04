// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
import "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps amountIn of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as ExactInputSingleParams in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
    }

    /// @notice Swaps amountIn of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as ExactInputParams in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint amountOut);
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}



// DAI SEPOLIA TOKEN = 0x82fb927676b53b6eE07904780c7be9b4B50dB80b
// LINK SEPOLIA TOKEN = 0xb227f007804c16546Bd054dfED2E7A1fD5437678
// DAI SEPOLIA HOLDER = 0xaC72905626c913a3225b233aFd3fAD382a7e5eFa

// ETH DAI ADDR = 0x6B175474E89094C44Da98b954EedeAC495271d0F
// ETH LINK ADDR = 0x514910771AF9Ca656af840dff83E8264EcF986CA
// ETH DAI HOLDER = 0x692fd9d0C2A00E66BF809fDc6DceA5107F5c9f86

// LINK PRICE FEED SEPOLIA = 0xc59E3633BAAC79493d908e63626716e204A45EdF
// LINK PRICE FEED ETHEREUM MAINNET = 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c
contract Trading {
    event DepositLINK(uint indexed linkAmount, uint indexed linkPrice);
    event WithdrawLINK(uint indexed linkSpent, uint indexed linkPrice);


    ISwapRouter constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    IERC20 private link = IERC20(LINK);
    IERC20 private dai = IERC20(DAI);
    AggregatorV3Interface internal linkPriceFeed;
    uint256 public lastPrice;
    uint256 public profitPercentage;

    constructor() {
        linkPriceFeed = AggregatorV3Interface(
            0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c
        );
    }

    function getLINKLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = linkPriceFeed.latestRoundData();
        return price;
    }
    function singleHopSwapFromUser(
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        uint amountIn
    ) public returns (uint amountOut) {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = router.exactInputSingle(params);
    }

    // This code doensn't work because I don't understand
    // how to work with eth or polygon mumbai testnet
    // tests just throw error when i try to fork it on mumbai or sepolia
    // when i am forking mainnet all is ok
    
    // function checkUpkeep(bytes calldata /* checkData */) external view returns (bool upkeepNeeded, bytes memory /* performData */) {
    //     // Check if the LINK price has grown by 10%
    //     int currentPrice = getLINKLatestPrice();
    //     if (uint256(currentPrice) > lastPrice * 11 / 10) {
    //         upkeepNeeded = true;
    //     } else {
    //         upkeepNeeded = false;
    //     }
    // }
    
    // function performUpkeep(bytes calldata /* performData */) external {
    //     // Calculate the profit and transfer it to the beneficiary
    //     int256 currentPrice = getLINKLatestPrice();
    //     uint256 profit = link.balanceOf(address(this)) * 10 / 100;
    //     link.transfer(msg.sender, profit);
        
    //     // Update the last price
    //     lastPrice = uint256(currentPrice);
    // }


    function depositLINK(uint _linkAmount) public {
        lastPrice = uint(getLINKLatestPrice());
        link.transferFrom(msg.sender, address(this), _linkAmount);
        emit DepositLINK(_linkAmount, uint(getLINKLatestPrice()));
    }
    function withdrawLINK(uint _linkAmount) public {
        link.transfer(msg.sender, _linkAmount);
        emit WithdrawLINK(_linkAmount, uint(getLINKLatestPrice()));
    }
}
