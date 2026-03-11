class PaymentData {
  String? status;
  String? statusMessage;
  int? orderId;
  String? accessCode;
  String? redirectUrl;
  String? cancelUrl;
  String? encVal;
  String? plain;

  PaymentData(
      {this.status,
      this.statusMessage,
      this.orderId,
      this.accessCode,
      this.redirectUrl,
      this.cancelUrl,
      this.encVal,
      this.plain});

  PaymentData.fromJson(Map<String, dynamic> json) {
    status = json['status'].toString();
    statusMessage = json['status_message'];
    orderId = json['order_id'];
    accessCode = json['access_code'];
    redirectUrl = json['redirect_url'];
    cancelUrl = json['cancel_url'];
    encVal = json['enc_request'];
    plain = json['plain'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['status_message'] = this.statusMessage;
    data['order_id'] = this.orderId;
    data['access_code'] = this.accessCode;
    data['redirect_url'] = this.redirectUrl;
    data['cancel_url'] = this.cancelUrl;
    data['enc_val'] = this.encVal;
    data['plain'] = this.plain;
    return data;
  }
}
 