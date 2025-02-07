export const handleClick = (click: MouseEvent) => {
  const clickedX = click.screenX;
  const clickedY = click.screenY;

  console.log(`clicking ${clickedX} ${clickedY}`);

  Byond.command(
    `.relay ${clickedX} ${clickedY} [[mainwindow.pos.x]] [[mainwindow.pos.y]] [[mainwindow.size.x]] [[mainwindow.size.y]] [[mapwindow.map.view-size.x]] [[mapwindow.map.view-size.y]] [[mainwindow.is-maximized]] [[mainwindow.is-fullscreen]]`,
  );
};
