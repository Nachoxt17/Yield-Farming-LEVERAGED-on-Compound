pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//+-Compound Finance main S.C.:_
import "./Icomptroller.sol";
import "./IcToken.sol";

contract YieldFarmer {
    Icomptroller comptroller;
    IcToken cDai;
    IERC20 dai;
    uint256 borrowFactor = 70;

    constructor(
        address comptrollerAddress,
        address cDaiAddress,
        address daiAddress
    ) public {
        comptroller = Icomptroller(comptrollerAddress);
        cDai = IcToken(cDaiAddress);
        dai = IERC20(daiAddress);
        address[] memory cTokens = new address[](1);
        cTokens[0] = cDaiAddress;
        //+-Compound Finance S.C. Function that allows us to Deposit our Tokens as a Collateral to Borrow more Tokens:_
        comptroller.enterMarkets(cTokens);
    }

    /**+-We send DAI as a collateral to Compound Finance to borrow more DAI and we do it 5 times using the borrowed Money, and 
    then we use the Total Money to do Yielding and Earn COMP Tokens:_*/
    function openPosition(uint256 initialAmount) external {
        uint256 nextCollateralAmount = initialAmount;
        for (uint256 i = 0; i < 5; i++) {
            nextCollateralAmount = _supplyAndBorrow(nextCollateralAmount);
        }
    }

    function _supplyAndBorrow(uint256 collateralAmount)
        internal
        returns (uint256)
    {
        dai.approve(address(cDai), collateralAmount);
        cDai.mint(collateralAmount);
        uint256 borrowAmount = (collateralAmount * 70) / 100;
        cDai.borrow(borrowAmount);
        return borrowAmount;
    }

    //+-We return the Borrowed Money and have our Earnings in COMP:_
    function closePosition() external {
        uint256 balanceBorrow = cDai.borrowBalanceCurrent(address(this));
        dai.approve(address(cDai), balanceBorrow);
        cDai.repayBorrow(balanceBorrow);
        uint256 balancecDai = cDai.balanceOf(address(this));
        cDai.redeem(balancecDai);
    }
}
