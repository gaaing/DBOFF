// --------------------------------------------------------------------------------------
// Dialog Setting

dialog dlgMain
{
	x	= 545;
 	y 	= 100;
	width	= 237;
	height	= 479;

	titlebar_x		= 0;
	titlebar_y		= 0;
	titlebar_width		= 153;
	titlebar_height		= 20;

	surface_file = "NpcTradeCart.srf";
	surface	     = "srfDlgMain";

	button	ExitButton
	{
		x		= 218;
		y		= 5;
		width		= 15;
		height		= 16;

		surface_file 	= "GameCommon.srf";
		surface_up 	= "srfCloseBtnUp";
		surface_down 	= "srfCloseBtnDown";
		surface_focus 	= "srfCloseBtnFoc";
	}

	button BuyButton
	{
		x	= 28;
	 	y 	= 430;
		width	= 69;
		height	= 23;

		surface_file 	= "GameCommon.srf";
		surface_up   	= "srfCommonBtnUp";
		surface_focus  	= "srfCommonBtnFoc";
		surface_down   	= "srfCommonBtnDown";
		surface_disable	= "srfCommonBtnDis";
	}

	button SellButton
	{
		x	= 140;
	 	y 	= 430;
		width	= 69;
		height	= 23;

		surface_file 	= "GameCommon.srf";
		surface_up   	= "srfCommonBtnUp";
		surface_focus  	= "srfCommonBtnFoc";
		surface_down   	= "srfCommonBtnDown";
		surface_disable	= "srfCommonBtnDis";
	}
}