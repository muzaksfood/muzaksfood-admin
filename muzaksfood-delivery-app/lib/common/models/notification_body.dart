class NotificationBody {
  String? title;
  String? body;
  int? orderId;
  String? type;
  String? image;
  String? userImage;
  String? userName;
  bool? isAssignedNotification;


  NotificationBody(
      {this.title, this.body, this.orderId, this.type, this.userImage, this.userName, this.isAssignedNotification});

  NotificationBody.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    body = json['body'];
    type = json['type'];
    image = (json['image'] != null && json['image'] !="") ? json['image'] : null;
    userImage = json['user_image'] != null && json['user_image'] != "" ? json['user_image'] : null;
    userName = json['user_name'] != null && json['user_name'] != "" ? json['user_name'] : null;
    orderId = int.tryParse(json['order_id'].toString());
    isAssignedNotification = json["is_deliveryman_assigned"] == '1';

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['body'] = body;
    data['type'] = type;
    data['image'] = image;
    data['user_image'] = userImage;
    data['user_name'] = userName;
    data['order_id'] = type;
    data['is_deliveryman_assigned'] = isAssignedNotification;
    return data;
  }
}
