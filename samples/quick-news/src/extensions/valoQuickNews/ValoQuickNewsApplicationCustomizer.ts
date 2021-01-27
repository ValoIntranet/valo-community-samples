import { BaseApplicationCustomizer } from '@microsoft/sp-application-base';
import QuickNews from './QuickNews'

export interface IValoQuickNewsApplicationCustomizerProperties {
  // This is an example; replace with your own property
  testMessage: string;
}

/** A Custom Action which can be run during execution of a Client Side Application */
export default class ValoQuickNewsApplicationCustomizer
  extends BaseApplicationCustomizer<IValoQuickNewsApplicationCustomizerProperties> {

  public onInit(): Promise<void> {

    // let message: string = this.properties.testMessage;
    // if (!message) {
    //   message = '(No properties were provided.)';
    // }

    const ValoQuickNews = new QuickNews();
    ValoQuickNews.register(this.context);
    return;
  }
}
